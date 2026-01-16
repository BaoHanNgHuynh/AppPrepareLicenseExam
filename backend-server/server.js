const express = require("express");
const axios = require("axios");
const bodyParser = require("body-parser");
const cors = require("cors");

const app = express();
const PORT = process.env.PORT || 8080;

require("dotenv").config();

// URL PocketBase (chạy local hoặc server)
//const POCKETBASE_URL = "http://127.0.0.1:8090";

const POCKETBASE_URL = process.env.PB_INTERNAL_URL; // server dùng nội bộ
const PB_PUBLIC_URL  = process.env.PB_PUBLIC_URL; // client dùng để tải file

app.use(cors());
app.use(bodyParser.json());

// ====== Auth middleware: xác thực PocketBase JWT ======
async function authPB(req, res, next) {
  try {
    const auth = req.headers.authorization || "";
    const token = auth.startsWith("Bearer ") ? auth.slice(7) : null;
    if (!token) return res.status(401).json({ message: "Missing Bearer token" });

    const { data } = await axios.post(
      `${POCKETBASE_URL}/api/collections/users/auth-refresh`,
      {},
      { headers: { Authorization: `Bearer ${token}` } }
    );

    req.user = {
      id: data?.record?.id,
      username: data?.record?.username,
      email: data?.record?.email,
    };
    req.pbAuthHeader = { Authorization: `Bearer ${token}` };
    next();
  } catch (err) {
    console.error("Auth error:", err?.response?.data || err?.message || err);
    return res.status(401).json({ message: "Invalid or expired token" });
  }
}
// === TAG chương: giá trị đúng của field `chapter_tag` trong collection `questions` ===
const CHAPTER_TAGS = {
  ch1:    "Chương I: Quy định chung và quy tắc giao thông",
  vanHoa: "Chương II: Văn hóa giao thông, đạo đức người lái xe, kỹ năng PCCC và cứu hộ, cứu nạn",
  kyThuat:"Chương III: Kỹ thuật lái xe",
  baoHieu:"Chương V: Biển báo giao thông",
  saHinh: "Chương VI: Giải thế sa hình và các tình huống giao thông",
};


// ====== SPEC 25 câu ======
const SPEC = { ch1:8, diemLiet:1, vanHoa:1, kyThuat:1, baoHieu:8, saHinh:6 };

// ====== PRNG & Utils ======
function mulberry32(a){
  return function(){
    let t = a += 0x6D2B79F5;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }
}

function sampleUnique(arr, k, seed){
  if (!Array.isArray(arr) || arr.length < k) {
    throw new Error(`Không đủ dữ liệu: cần ${k}, chỉ có ${arr?.length || 0}`);
  }
  const rnd = mulberry32(seed);
  const used = new Set();
  const out = [];
  while (out.length < k) {
    const i = Math.floor(rnd() * arr.length);
    if (!used.has(i)) { used.add(i); out.push(arr[i]); }
  }
  return out;
}
function shuffleInPlace(a, seed){
  const r = mulberry32(seed);
  for (let i=a.length-1;i>0;i--){
    const j = Math.floor(r()*(i+1));
    [a[i],a[j]]=[a[j],a[i]];
  }
}

// khi build ảnh, luôn dùng PB_PUBLIC_URL:
const fileUrl = (col, id, file) => {
  const name = Array.isArray(file) ? file[0] : file; // PB file field có thể là mảng
  return name
    ? `${PB_PUBLIC_URL}/api/files/${col}/${id}/${encodeURIComponent(name)}`
    : null;
};

// ====== Cache chapter IDs theo title ======
const CHAPTER_IDS = {}; 
let chapterIdsReady = null;

async function getChapterIdByTitle(title) {
  const { data } = await axios.get(
    `${POCKETBASE_URL}/api/collections/chapters/records`,
    { params: { filter: `title="${title}"`, perPage: 1 } }
  );
  const item = (data.items || [])[0];
  if (!item) throw new Error(`Không tìm thấy chapter: ${title}`);
  return item.id;
}
async function resolveChapterIds() {
  if (chapterIdsReady) return chapterIdsReady;
  chapterIdsReady = (async () => {
    CHAPTER_IDS.ch1     = await getChapterIdByTitle(CHAPTER_TAGS.ch1);
    CHAPTER_IDS.vanHoa  = await getChapterIdByTitle(CHAPTER_TAGS.vanHoa);
    CHAPTER_IDS.kyThuat = await getChapterIdByTitle(CHAPTER_TAGS.kyThuat);
    CHAPTER_IDS.baoHieu = await getChapterIdByTitle(CHAPTER_TAGS.baoHieu);
    CHAPTER_IDS.saHinh  = await getChapterIdByTitle(CHAPTER_TAGS.saHinh);
    return CHAPTER_IDS;
  })();
  return chapterIdsReady;
}


// ====== Data fetchers ======
async function fetchByChapterId(chapterId, { excludeDiemLiet = false } = {}) {
  const filter = excludeDiemLiet
    ? `chapter_tag="${chapterId}" && isDiemLiet=false `
    : `chapter_tag="${chapterId}"`;

  const { data } = await axios.get(
    `${POCKETBASE_URL}/api/collections/questions/records`,
    { params: { filter, perPage: 200 } }
  );

  return data.items || [];
}

// Dùng theo tiêu đề (nếu bạn muốn tạo đề nhanh bằng tên hiển thị)
async function fetchByChapterTag(tagValue, { excludeDiemLiet = false } = {}) {
  const chapId = await getChapterIdByTitle(tagValue);
  return fetchByChapterId(chapId, { excludeDiemLiet });
}

async function fetchDiemLiet() {
  const { data } = await axios.get(
    `${POCKETBASE_URL}/api/collections/questions/records`,
    { params: { filter: `isDiemLiet=true`, perPage: 200 } }
  );
  return data.items || [];
}

// helpers cho tiến trình
async function countTotalQuestions(chapterTag) {
  const filter = encodeURIComponent(`chapter_tag="${chapterTag}"`);
  const { data } = await axios.get(
    `${POCKETBASE_URL}/api/collections/questions/records?filter=${filter}&perPage=1`
  );
  return data?.totalItems ?? 0;
}

async function getLatestAttemptsByChapter(userId, chapterTag, authHeader) {
  let page = 1;
  const perPage = 200;
  const all = [];
  const filter = encodeURIComponent(`user_id="${userId}" && chapter_tag="${chapterTag}"`);
  const config = authHeader ? { headers: authHeader } : undefined;

  while (true) {
    const { data } = await axios.get(
      `${POCKETBASE_URL}/api/collections/practice_attempts/records?filter=${filter}&page=${page}&perPage=${perPage}&sort=-created`,
      config
    );
    const items = data?.items || [];
    all.push(...items);
    if (items.length < perPage) break;
    page++;
  }

  const latestByQ = new Map(); // mới nhất theo question_id
  for (const it of all) {
    const qid = it.question_id;
    if (!latestByQ.has(qid)) latestByQ.set(qid, it); // đã sort -created
  }
  return Array.from(latestByQ.values());
}

async function createAttempt({ userId, questionId, chapterTag, isCorrect, source, authHeader }) {
  try {
    const payload = {
      user_id: userId,
      question_id: questionId,
      chapter_tag: chapterTag,
      is_correct: isCorrect,
      ...(source ? {  source } : {}),
    };
     const config = authHeader ? { headers: authHeader } : undefined;

    await axios.post(
      `${POCKETBASE_URL}/api/collections/practice_attempts/records`,
      payload,
      config
    );
   

    
  } catch (e) {
    console.error('❌ Lỗi createAttempt:', e.response?.data || e.message);
    throw e;
  }
}

async function recomputeChapterProgress({ userId, chapterTag, authHeader }) {
  const latest = await getLatestAttemptsByChapter(userId, chapterTag, authHeader);
  const questions_attempted = latest.length;
  const questions_correct = latest.filter(x => !!x.is_correct).length;
  const total_questions = await countTotalQuestions(chapterTag);

  const recent = latest
    .sort((a, b) => new Date(b.created) - new Date(a.created))
    .slice(0, 10)
    .map(x => ({ qid: x.question_id, correct: !!x.is_correct, at: x.created }));

  const payload = {
    user_id: userId,
    chapter_tag: chapterTag,
    questions_attempted,
    questions_correct,
    total_questions,
    recent_result: recent,
    last_updated: new Date().toISOString(),
  };

  const filter = encodeURIComponent(`user_id="${userId}" && chapter_tag="${chapterTag}"`);
    const config = authHeader ? { headers: authHeader } : undefined;

  const { data } = await axios.get(
    `${POCKETBASE_URL}/api/collections/progress/records?filter=${filter}&perPage=1`,
    config
  );

  if ((data?.items?.length ?? 0) > 0) {
    const id = data.items[0].id;
   await axios.patch(
      `${POCKETBASE_URL}/api/collections/progress/records/${id}`,
      payload,
      config
    );
    return { id, ...payload };
  } else {
    const created = await axios.post(`${POCKETBASE_URL}/api/collections/progress/records`, payload, config);
    return { id: created.data?.id, ...payload };
  }
}
async function insertWrongOnce({ userId, questionId, source, chapterTag, authHeader }) {
  const filter = encodeURIComponent(`user_id="${userId}" && question_id="${questionId}"`);
    const config = authHeader ? { headers: authHeader } : undefined;
  const { data } = await axios.get(`${POCKETBASE_URL}/api/collections/wrong_questions/records?filter=${filter}&perPage=1&page=1`, config);

  if ((data?.items?.length ?? 0) > 0) return data.items[0].id;


  const payload = {
    user_id: userId,
    question_id: questionId,
    ...(source ? {  source } : {}),           // 'random' | 'chapter' | 'critical'
    ...(chapterTag ? { chapter_tag: chapterTag } : {}),
  };

 const created = await axios.post(`${POCKETBASE_URL}/api/collections/wrong_questions/records`, payload, config);
  return created?.data?.id;
}


// API Đăng ký
app.post("/api/register", async (req, res) => {
  try {
    const { username, email, password } = req.body;

    const response = await axios.post(
      `${POCKETBASE_URL}/api/collections/users/records`,
      {
        username,
        email,
        password,
        passwordConfirm: password,
      }
    );

    res.status(200).json({
      message: "Đăng ký thành công",
      data: response.data,
    });
  } catch (error) {
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      res.status(500).json({ error: "Lỗi server backend" });
    }
  }
});


//  API Đăng nhập
app.post("/api/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    // Gọi PocketBase API để đăng nhập
    const response = await axios.post(
      `${POCKETBASE_URL}/api/collections/users/auth-with-password`,
      {
        identity: email,
        password: password,
      }
    );

    res.status(200).json({
      message: "Đăng nhập thành công",
      token: response.data.token,
      user: response.data.record,
    });
  } catch (error) {
    if (error.response) {
      const errData = error.response.data;

      // Xử lý lỗi cụ thể
      let message = "Đăng nhập thất bại";
      if (errData?.data?.identity) {
        message = "Tài khoản không tồn tại";
      } else if (errData?.data?.password) {
        message = "Sai mật khẩu";
      } 

      return res.status(error.response.status).json({ message });
    }

    res.status(500).json({ error: "Lỗi server backend" });
  }
});

// API lấy danh sách tất cả chương  (chapter)
app.get("/api/chapters", async (req, res) => {
  try {
    const response = await axios.get(`${POCKETBASE_URL}/api/collections/chapters/records`);
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: "Không lấy được danh sách chương" });
  }
});

// Lấy chi tiết 1 chương 
app.get("/api/chapters/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const response = await axios.get(`${POCKETBASE_URL}/api/collections/chapters/records/${id}`);
    res.json(response.data);
  } catch (error) {
    res.status(404).json({ error: "Không tìm thấy chương" });
  }
});

// lấy danh sách tất cả bài học 
app.get("/api/lessons", async (req, res) => {
  try {
    const response = await axios.get(`${POCKETBASE_URL}/api/collections/lessons/records`);
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: "Không lấy được danh sách bài học" });
  }
});

// Lấy chi tiết 1 bài học
app.get("/api/lessons/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const response = await axios.get(`${POCKETBASE_URL}/api/collections/lessons/records/${id}`);
    res.json(response.data);
  } catch (error) {
    res.status(404).json({ error: "Không tìm thấy bài học" });
  }
});

// Lấy danh sách bài học theo chapter_id
app.get("/api/lessons/by-chapter/:chapterId", async (req, res) => {
  try {
    const { chapterId } = req.params;
    const response = await axios.get(
      `${POCKETBASE_URL}/api/collections/lessons/records?filter=chapter_id="${chapterId}"`
    );
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: "Không lấy được bài học của chương này" });
  }
});

// Lấy nội dung bài học theo lesson_id
app.get("/api/lesson-contents/by-lesson/:lessonId", async (req, res) => {
  try {
    const { lessonId } = req.params;
    const {data} = await axios.get(
      `${POCKETBASE_URL}/api/collections/lesson_contents/records?filter=(lesson_id="${lessonId}")`
    );

    const items = (data.items || []).map((item) => ({
      title: item.title,
      content: item.content,
      image: fileUrl("lesson_contents", item.id, item.image), // DÙNG PB_PUBLIC_URL
    }));

    res.json(items);
  } catch (error) {
    res.status(500).json({ error: "Không lấy được nội dung của bài học" });
  }
});


// hàm xáo trộn mảng
function shuffle(arr) {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

// chuẩn hóa dữ liệu câu hỏi
function mapQuestion(rec) {
  return {
    id: rec.id,
    indexNumber: rec.indexNumber,
    questionText: rec.questionText,
    answers: rec.answers,
    correctAnswerIndex: rec.correctAnswerIndex,
    isDiemLiet: !!rec.isDiemLiet,
      image: rec.image
      ? `${PB_PUBLIC_URL}/api/files/questions/${rec.id}/${encodeURIComponent(
          Array.isArray(rec.image) ? rec.image[0] : rec.image
        )}`
      : null,
    explain: rec.explain ?? null,
    chapter_tag: rec.chapter_tag ?? null,
  };
}
// Ôn tập theo CHƯƠNG (dùng relation id)
app.get('/api/questions', async (req, res) => {
  try {
    const { chapterId, limit} = req.query;
    if (!chapterId) return res.status(400).json({ error: 'Thiếu chapterId' });

    const { data } = await axios.get(
      `${POCKETBASE_URL}/api/collections/questions/records`,
      { params: { filter: `chapter_tag="${chapterId}"`, perPage: 200, page: 1 } }
    );

    const items = (data.items || []).map(mapQuestion);
    let out = shuffle(items);
    if (limit) {
    const n = Number(limit);
    if (!Number.isNaN(n) && n > 0) {
      out = out.slice(0, n);
    }
}

    res.json(out);
  } catch (err) {
    console.error(err?.message || err);
    res.status(500).json({ error: 'Không lấy được câu hỏi ôn tập' });
  }
});


app.get("/api/exams/random", async (req, res) => {
  try {
    const seed = Date.now(); // mỗi lần vào → seed khác
    const ids = await resolveChapterIds();

    const [ch1, diemLiet, vanHoa, kyThuat, baoHieu, saHinh] = await Promise.all([
      fetchByChapterId(ids.ch1,     { excludeDiemLiet: true }),
      fetchDiemLiet(),
     fetchByChapterId(ids.vanHoa,  { excludeDiemLiet: true }),
      fetchByChapterId(ids.kyThuat, { excludeDiemLiet: true }),
       fetchByChapterId(ids.baoHieu, { excludeDiemLiet: true }),
      fetchByChapterId(ids.saHinh,  { excludeDiemLiet: true }),
    ]);

    const picked = [
      ...sampleUnique(ch1,     8, seed + 11),
      ...sampleUnique(diemLiet,1, seed + 22),
      ...sampleUnique(vanHoa,  1, seed + 33),
      ...sampleUnique(kyThuat, 1, seed + 44),
      ...sampleUnique(baoHieu, 8, seed + 55),
      ...sampleUnique(saHinh,  6, seed + 66),
    ];

    shuffleInPlace(picked, seed + 99);

    res.json({
      type: "random",
      seed,
      total: picked.length,
      questions: picked.map(mapQuestion),
      spec: SPEC,
    });
  } catch (err) {
    console.error("❌ Lỗi tạo đề ngẫu nhiên:", err.message);
    res.status(500).json({ error: "Không tạo được đề ngẫu nhiên" });
  }
});

// lấy 20 câu điểm liệt
app.get('/api/questions/diem-liet', async (req, res) => {
  try {
    const limit = Math.max(1, Math.min(Number(req.query.limit) || 20, 100));

    // isDiemLiet là boolean => filter đúng là không có ngoặc kép
    const filter = encodeURIComponent('isDiemLiet=true');

      const { data } = await axios.get(
      `${POCKETBASE_URL}/api/collections/questions/records?filter=${filter}&perPage=200&page=1`
    );
    const items = (data.items || []).map(mapQuestion);
    const out = shuffle(items).slice(0, limit);
    res.json(out);
  } catch (err) {
    console.error('❌ Lỗi lấy câu điểm liệt:', err?.message || err);
    res.status(500).json({ error: 'Không lấy được câu điểm liệt' });
  }
});


// Tạo đề mẫu (dùng CHAPTER_TAGS theo tiêu đề)
app.get("/api/exams/generate", async (req, res) => {
  try {
    const seed = Number(req.query.seed ?? Date.now());
    const wantFull = req.query.full === "1";

    const [ch1, diemLiet, vanHoa, kyThuat, baoHieu, saHinh] = await Promise.all([
      fetchByChapterTag(CHAPTER_TAGS.ch1, { excludeDiemLiet: true }),
      fetchDiemLiet(),
      fetchByChapterTag(CHAPTER_TAGS.vanHoa, { excludeDiemLiet: true }),
      fetchByChapterTag(CHAPTER_TAGS.kyThuat, { excludeDiemLiet: true }),
      fetchByChapterTag(CHAPTER_TAGS.baoHieu, { excludeDiemLiet: true }),
      fetchByChapterTag(CHAPTER_TAGS.saHinh,   { excludeDiemLiet: true }),
    ]);

    const picked = [
      ...sampleUnique(ch1,     8, seed + 11),
      ...sampleUnique(diemLiet,1, seed + 22),
      ...sampleUnique(vanHoa,  1, seed + 33),
      ...sampleUnique(kyThuat, 1, seed + 44),
      ...sampleUnique(baoHieu, 8, seed + 55),
      ...sampleUnique(saHinh,  6, seed + 66),
    ];
    shuffleInPlace(picked, seed + 99);

    if (!wantFull) {
      return res.json({
        seed,
        total: picked.length,
        ids: picked.map(q => q.id),
        spec: SPEC
      });
    }

    res.json({
      seed,
      total: picked.length,
      questions: picked.map(mapQuestion),
      spec: SPEC,
    });
  } catch (err) {
    const msg = err?.message || String(err);
    if (msg.startsWith("Không đủ dữ liệu")) return res.status(400).json({ error: msg });
    console.error("❌ Lỗi tạo đề:", msg);
    res.status(500).json({ error: "Không tạo được đề thi" });
  }
});
// Danh sách đề (lấy danh sách đề từ exam_sets)
app.get("/api/exams", async (_req, res) => {
  try {
    const { data } = await axios.get(
      `${POCKETBASE_URL}/api/collections/exam_sets/records`,
      { params: { sort: "name", perPage: 100 } }
    );

    const items = (data.items || []).map(it => ({
      id: it.id,
      name: it.name,
      total: Array.isArray(it.question_ids) ? it.question_ids.length : 25, // mặc định 25 câu
      timeLimit: Number(it.time_limit ?? 1140),
      created: it.created,
    }));

    res.json(items);
  } catch (err) {
    console.error("❌ Lỗi lấy danh sách đề:", err?.response?.data || err);
    res.status(404).json({ error: "Không lấy được danh sách đề" });
  }
});
// Chi tiết 1 đề thi (expand 25 câu hỏi)
app.get("/api/exams/:id", async (req, res) => {
  try {
    const id = req.params.id;
    console.log("📥 /api/exams/:id -> id =", id);
    console.log("POCKETBASE_URL =", POCKETBASE_URL);


    const { data: examSet } = await axios.get(
      `${POCKETBASE_URL}/api/collections/exam_sets/records/${id}`
    );

    // 2️⃣ lấy danh sách câu hỏi thuộc đề này, expand question_id
    const { data } = await axios.get(
      `${POCKETBASE_URL}/api/collections/exam_questions/records`,
      {
        params: {
          filter: `exam_set="${id}"`,
          expand: "question_id, question_id.chapter_tag",
          perPage: 200,
          sort: "order",
        },
      }
    );

    // 3️⃣ chuẩn hóa output
    const questions = (data.items || [])
      .map(it => {
        const q = it.expand?.question_id;
        if (!q) return null;
         const ch = q.expand?.chapter_tag;
        const chapterLabel = ch?.tag || ch?.title || null;
        return {
          id: q.id,
          questionText: q.questionText,
          answers: q.answers,
          correctAnswerIndex: q.correctAnswerIndex,
          isDiemLiet: !!q.isDiemLiet,
          image: q.image
            ? `${PB_PUBLIC_URL}/api/files/questions/${q.id}/${encodeURIComponent(
                Array.isArray(q.image) ? q.image[0] : q.image
              )}`
            : null,
          explain: q.explain ?? null,
          chapter_tag: q.chapter_tag ?? null,
           chapter_title: chapterLabel, 
        };
      })
      .filter(Boolean);

    res.json({
      id: examSet.id,
      name: examSet.name ?? examSet.exam_sets,
      total: questions.length,
      timeLimit: Number(examSet.time_limit ?? 1140),
      questions,
    });
  } catch (err) {
    console.error("❌ Lỗi lấy chi tiết đề:", err?.response?.data || err);
    res.status(404).json({ error: "Không lấy được chi tiết đề" });
  }
});


// Tạo & lưu đề (25 câu theo cơ cấu) — dùng relation ID
app.post("/api/exams", async (req, res) => {
  try {
    const name = req.body?.name || `Đề ${Date.now() % 1000}`;
    const timeLimit = Number(req.body?.timeLimit ?? 1140);
    const seed = Number(req.body?.seed ?? Date.now());

    console.log(" Bắt đầu tạo đề:", name, "seed=", seed);

    const ids = await resolveChapterIds();

    // 1️⃣ Lấy pool câu hỏi từng chương
    const [ch1, diemLiet, vanHoa, kyThuat, baoHieu, saHinh] = await Promise.all([
      fetchByChapterId(ids.ch1, { excludeDiemLiet: true }),
      fetchDiemLiet(),
      fetchByChapterId(ids.vanHoa, { excludeDiemLiet: true }),
      fetchByChapterId(ids.kyThuat, { excludeDiemLiet: true }),
      fetchByChapterId(ids.baoHieu,{ excludeDiemLiet: true }),
      fetchByChapterId(ids.saHinh,{ excludeDiemLiet: true }),
    ]);

    // 2️⃣ Chọn ngẫu nhiên theo seed và SPEC
    const picked = [
      ...sampleUnique(ch1, SPEC.ch1, seed + 11),
      ...sampleUnique(diemLiet, SPEC.diemLiet, seed + 22),
      ...sampleUnique(vanHoa, SPEC.vanHoa, seed + 33),
      ...sampleUnique(kyThuat, SPEC.kyThuat, seed + 44),
      ...sampleUnique(baoHieu, SPEC.baoHieu, seed + 55),
      ...sampleUnique(saHinh, SPEC.saHinh, seed + 66),
    ];
    shuffleInPlace(picked, seed + 99);

    const questionIds = picked.map(q => q.id);

    console.log("✅ Đề gồm:", questionIds.length, "câu.");

    // 3️⃣ Tạo record exam_sets
    const { data: examSet } = await axios.post(
      `${POCKETBASE_URL}/api/collections/exam_sets/records`,
      {
        name,
        time_limit: timeLimit,
        seed,
        spec: SPEC,
      }
    );

    // 4️⃣ Tạo từng exam_questions (25 record)
    await Promise.all(
      questionIds.map((qid, idx) =>
        axios.post(`${POCKETBASE_URL}/api/collections/exam_questions/records`, {
          exam_set: examSet.id,
          question_id: qid,
          order: idx + 1,
        })
      )
    );

    res.status(201).json({
      id: examSet.id,
      name: examSet.name,
      total: questionIds.length,
      seed,
    });
  } catch (err) {
    const msg = err?.response?.data || err?.message || String(err);
    console.error("❌ Lỗi tạo đề:", msg);
    res.status(500).json({ error: "Không tạo được đề thi" });
  }
});

// ====== Practice & Progress (có authPB) ======

// 1) Ghi lịch sử + cập nhật tiến trình
app.post('/api/practice/attempt', authPB, async (req, res) => {
  try {
    const userId = req.user?.id;
    const { questionId, chapterTag, isCorrect, source } = req.body || {};
    if (!userId) return res.status(401).json({ message: 'Unauthenticated' });
    if (!questionId || !chapterTag || typeof isCorrect !== 'boolean') {
      return res.status(400).json({ message: 'Missing questionId/chapterTag/isCorrect' });
    }
        const authHeader = req.pbAuthHeader; 
    await createAttempt({ userId, questionId, chapterTag, isCorrect, source, authHeader });
     if (isCorrect === false) {
      await insertWrongOnce({ userId, questionId, source, chapterTag, authHeader});
    }
    const progress = await recomputeChapterProgress({ userId, chapterTag, authHeader});
    res.json({ ok: true, progress });
  } catch (e) {
    console.error('❌ Lỗi khi xử lý /practice/attempt:', e.response?.data || e.message);
    res.status(500).json({ ok: false, error: e.message });
  }
});

// 2) Lấy tiến trình 1 chương
app.get('/api/progress/:chapterTag', authPB, async (req, res) => {
  try {
    const userId = req.user?.id;
    const chapterTag = req.params.chapterTag;
    if (!userId) return res.status(401).json({ message: 'Unauthenticated' });

    const filter = encodeURIComponent(`user_id="${userId}" && chapter_tag="${chapterTag}"`);
    const { data } = await axios.get(
      `${POCKETBASE_URL}/api/collections/progress/records?filter=${filter}&perPage=1`,
       { headers: req.pbAuthHeader }
    );
    const item = data?.items?.[0];

    if (!item) {
      const total = await countTotalQuestions(chapterTag);
      return res.json({
        user_id: userId,
        chapter_tag: chapterTag,
        questions_attempted: 0,
        questions_correct: 0,
        total_questions: total,
        recent_result: [],
        last_updated: null,
      });
    }
    res.json(item);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
});

// 3) Lấy tiến trình tất cả chương
app.get('/api/progress', authPB, async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ message: "Unauthenticated" });

    // 1. Lấy toàn bộ progress
    const { data: progressRes } = await axios.get(
      `${POCKETBASE_URL}/api/collections/progress/records` +
        `?filter=${encodeURIComponent(`user_id="${userId}"`)}&perPage=200&sort=chapter_tag`,
      { headers: req.pbAuthHeader }
    );

    const progressItems = progressRes?.items ?? [];

    if (progressItems.length === 0) {
      return res.json([]); // user chưa học gì
    }

    // 2. Lấy bảng chapters để map ID → tên chương
    const { data: chaptersRes } = await axios.get(
      `${POCKETBASE_URL}/api/collections/chapters/records?perPage=200`,
      { headers: req.pbAuthHeader }
    );

    const chapterItems = chaptersRes?.items ?? [];

    // Tạo map id → tag (hoặc title)
    const chapterMap = new Map(
      chapterItems.map(ch => [ch.id, ch.tag || ch.title])
    );

    // 3. Map lại dữ liệu, đổi chương_id → chương_tag đẹp
    const result = progressItems.map(p => {
      const chapterId = p.chapter_tag; // hiện đang là id
      const label = chapterMap.get(chapterId); // "Chương 1", "Chương 2"...

      return {
        ...p,
        chapter_id: chapterId,
        chapter_tag: label ?? chapterId,   // label đẹp cho UI
      };
    });

    res.json(result);

  } catch (e) {
    console.error("❌ Lỗi /api/progress:", e);
    res.status(500).json({ error: e.message });
  }
});

// Wrong question

app.get('/api/wrong', authPB, async (req, res) => {
  try {
    const userId = req.user?.id;
    const { source, chapterTag, page = 1, perPage = 50 } = req.query;

    const clauses = [`user_id="${userId}"`];
    if (source)     clauses.push(`source="${source}"`);           // random|chapter|critical
    if (chapterTag) clauses.push(`chapter_tag="${chapterTag}"`);

    const filter = encodeURIComponent(clauses.join(' && '));
    // expand question_id để FE render nhanh
    const url = `${POCKETBASE_URL}/api/collections/wrong_questions/records?filter=${filter}&expand=question_id&page=${page}&perPage=${perPage}&sort=-created`;
    const { data } = await axios.get(url, { headers: req.pbAuthHeader });
    res.json({ ok: true, ...data });
  } catch (e) {
    console.error(e);
    res.status(500).json({ ok: false, error: e.message });
  }
});

// Xoá 1 mục: /api/wrong/:id
app.delete('/api/wrong/:id', authPB, async (req, res) => {
  try {
    const userId = req.user?.id;
    const recId  = req.params.id;

    // Đảm bảo record thuộc user
    const { data: rec } = await axios.get(`${POCKETBASE_URL}/api/collections/wrong_questions/records/${recId}`);
    if (rec.user_id !== userId) return res.status(403).json({ ok: false, error: 'Forbidden' });

    await axios.delete(`${POCKETBASE_URL}/api/collections/wrong_questions/records/${recId}`, { headers: req.pbAuthHeader });
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

// Xoá loạt theo filter tab hiện tại: POST /api/wrong/clear { source?, chapterTag? }
app.post('/api/wrong/clear', authPB, async (req, res) => {
  try {
    const userId = req.user?.id;
    const { source, chapterTag } = req.body || {};
    const clauses = [`user_id="${userId}"`];
    if (source)     clauses.push(`source="${source}"`);
    if (chapterTag) clauses.push(`chapter_tag="${chapterTag}"`);
    const filter = encodeURIComponent(clauses.join(' && '));

    // Lấy tất cả rồi xoá 
    const { data } = await axios.get(`${POCKETBASE_URL}/api/collections/wrong_questions/records?filter=${filter}&perPage=200`,{ headers: req.pbAuthHeader });
    const ids = (data?.items || []).map(x => x.id);
    await Promise.all(ids.map(id => axios.delete(`${POCKETBASE_URL}/api/collections/wrong_questions/records/${id}`, { headers: req.pbAuthHeader })));

    res.json({ ok: true, deleted: ids.length });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

// ====== Exam results / History (có authPB) ======

// Lưu kết quả 1 lần thi đề chính thức
app.post("/api/exam-results", authPB, async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ message: "Unauthenticated" });

    const {
      examId,         
       totalQuestion,  
      correct,
      diemLietWrong,
      passed,
      time,             
      chapterResult, 
  
    } = req.body || {};

    if (!examId || typeof totalQuestion !== "number" || typeof correct !== "number") {
      return res.status(400).json({ message: "Missing examId/totalQuestion/correct" });
    }

    const payload = {
      user_id: userId,
      exam: examId,
      total_question: totalQuestion,
      correct,
      diem_liet_wrong: diemLietWrong ?? 0,
      passed: !!passed,
      time: Number(time ?? 0),
      chapter_result: chapterResult ?? null,
      
    };

    const { data } = await axios.post(
      `${POCKETBASE_URL}/api/collections/result_exam/records`,
      payload,
      { headers: req.pbAuthHeader }
    );

    res.status(201).json({ ok: true, data });
  } catch (e) {
    console.error("❌ Lỗi /api/exam-results (POST):", e.response?.data || e.message);
    res.status(500).json({ ok: false, error: e.message });
  }
});

// Lấy lịch sử thi của user hiện tại
app.get("/api/exam-results", authPB, async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ message: "Unauthenticated" });

    const { page = 1, perPage = 50 } = req.query;

    const filter = encodeURIComponent(`user_id="${userId}"`);
    const url =
      `${POCKETBASE_URL}/api/collections/result_exam/records` +
      `?filter=${filter}&page=${page}&perPage=${perPage}&expand=exam`;

    const { data } = await axios.get(url, { headers: req.pbAuthHeader });

    // Chuẩn hoá nhẹ cho FE (thêm examName, timeLimit)
    const items = (data.items || []).map((it) => {
      const exam = it.expand?.exam;
      return {
        id: it.id,
        examId: it.exam,
        examName: exam?.name ?? "Đề thi",
        timeLimit: Number(exam?.time_limit ?? 1140),
        totalQuestion: it.total_question,
        correct: it.correct,
        diemLietWrong: it.diem_liet_wrong,
        passed: !!it.passed,
        time: it.time,
        chapterResult: it.chapter_result,
         
        created: it.created,
      };
    });

    res.json({
      page: data.page,
      perPage: data.perPage,
      totalItems: data.totalItems,
      items,
    });
  } catch (e) {
    console.error("❌ Lỗi /api/exam-results (GET):", e.response?.data || e.message);
    res.status(500).json({ ok: false, error: e.message });
  }
});

// Chi tiết 1 lần thi
app.get("/api/exam-results/:id", authPB, async (req, res) => {
  try {
    const userId = req.user?.id;
    const id = req.params.id;

    const { data } = await axios.get(
      `${POCKETBASE_URL}/api/collections/result_exam/records/${id}?expand=exam`,
      { headers: req.pbAuthHeader }
    );

    if (data.user_id !== userId) {
      return res.status(403).json({ ok: false, error: "Forbidden" });
    }

    const exam = data.expand?.exam;
    res.json({
      id: data.id,
      examId: data.exam,
      examName: exam?.name ?? "Đề thi",
      timeLimit: Number(exam?.time_limit ?? 1140),
      totalQuestion: data.total_question,
      correct: data.correct,
      diemLietWrong: data.diem_liet_wrong,
      passed: !!data.passed,
      time: data.time,
      chapterResult: data.chapter_result,
      created: data.created,
    });
  } catch (e) {
    console.error("❌ Lỗi /api/exam-results/:id:", e.response?.data || e.message);
    res.status(500).json({ ok: false, error: e.message });
  }
});



app.listen(PORT, () => {
  console.log(`✅ Backend chạy tại http://localhost:${PORT}`);
});

