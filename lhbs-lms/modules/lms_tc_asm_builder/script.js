/* TS_1788115753171 */
/* COMPILE_TIMESTAMP_1788114868945 */
if (typeof window !== 'undefined') {
    if (!window.errorState) {
        window.errorState = {
            ui: { visible: false, message: '', show() {}, hide() {} },
            api: { visible: false, message: '', code: null, status: null, show() {}, hide() {} }
        };
    }
    if (!window.loadingState) {
        window.loadingState = { count: 0, text: 'Đang xử lý...', get loading() { return false; } };
    }
    if (!window.staleDataState) {
        window.staleDataState = { visible: false, retryCallback: null, show() {}, hide() {} };
    }
}
function isCheckAllGroupFullQuiz(groups) {
    let isNotFullQuiz = false
    if (!groups) return isNotFullQuiz
    for (var group of groups) {
        for (var question of group.questions) {
            let isCheck = question.type.includes('QUIZ') ? true : false
            if (!isCheck) {
                return true
            }
        }
    }
    return isNotFullQuiz
}
function isCheckGroupHasAnswerQuestionNotChoose(groups) {
    const obj = {
        isNotChoose: false,
        questionNotChooses: [],
        message: null
    }
    if (!groups) return obj
    for (var group of groups) {
        for (var question of group.questions) {
            let isCheck = isCheckAnswerQuestionNotChoose(question)
            if (isCheck) {
                obj.isNotChoose = true
                obj.questionNotChooses.push(question)
            }
        }
    }
    const numberQuestions = obj.questionNotChooses.map(x => 'Câu ' + x.ordinalNumber)
    obj.message = numberQuestions.join(', ') ?? ''
    return obj
}
function isCheckAnswerQuestionNotChoose(question) {
    let flag = false
    const config = question.config
    if (!config) return flag
    if (question.type === "QUIZ_SINGLE_CHOICE") {
        if (!config.correctAnswer) flag = true
        else if (Array.isArray(config.options) && !config.options.some(o => o.id === config.correctAnswer)) flag = true
    }
    if (question.type === "QUIZ_MULTIPLE_CHOICE") {
        if (!config.correctAnswers || config.correctAnswers.length === 0) flag = true
        else if (Array.isArray(config.options)) {
            const optionIds = config.options.map(o => o.id)
            if (!config.correctAnswers.every(id => optionIds.includes(id))) flag = true
        }
    }
    if (question.type === "QUIZ_TRUE_FALSE")
        if (config.correctAnswer !== true && config.correctAnswer !== false) flag = true
    if (question.type === "QUIZ_MULTIPLE_TRUE_FALSE") {
        if (!Array.isArray(config.options) || config.options.length === 0) flag = true
        for (var option of (config.options || [])) {
            if (!option?.correctAnswer && !option?.inCorrectAnswer) {
                flag = true
                break;
            }
        }
    }
    if (question.type === "QUIZ_FILL_IN_BLANK") {
        if (!Array.isArray(config.parts) || config.parts.length === 0) {
            flag = true
        }
        if (!(config.parts || []).find(x => x.type === 'blank')) flag = true
        for (var part of (config.parts || [])) {
            if (part.type !== "blank") continue
            const accepted = Array.isArray(part.acceptedAnswers)
                ? part.acceptedAnswers
                : (part.acceptedAnswers != null ? [part.acceptedAnswers] : [])
            const normalized = accepted
                .map(x => normalizeAcceptedAnswerKey(x))
                .filter(Boolean)
            if (normalized.length === 0) {
                flag = true
            }
        }
    }
    if (question.type === "QUIZ_MATCHING" || question.type === "QUIZ_MATCHING_V2") {
        const pairs = Array.isArray(config.correctPairs) ? config.correctPairs : []
        const columnAIds = new Set((config.columnA || []).map(item => String(item?.id)))
        const columnBIds = new Set((config.columnB || []).map(item => String(item?.id)))
        // Content Hub lưu cặp nối theo from/to, còn dữ liệu cũ của Soạn bài tập dùng aId/bId.
        // Chấp nhận cả hai schema để không báo thiếu đáp án khi import câu hỏi từ Content Hub.
        if (pairs.length === 0 || pairs.some(pair => !columnAIds.has(String(pair?.aId ?? pair?.leftId ?? pair?.sourceId ?? pair?.from)) || !columnBIds.has(String(pair?.bId ?? pair?.rightId ?? pair?.targetId ?? pair?.to)))) {
            flag = true
        }
    }
    if (question.type === "QUIZ_ORDERING") {
        // `items` là nội dung các ý; `correctOrder` là danh sách ID theo thứ tự đúng.
        // Kiểm tra cả hai để câu hỏi không được lưu khi thiếu ý hoặc trỏ tới ID không tồn tại.
        const items = Array.isArray(config.items) ? config.items : []
        const itemIds = items.map(item => String(item?.id ?? ''))
        const uniqueItemIds = new Set(itemIds)
        const correctOrder = Array.isArray(config.correctOrder) ? config.correctOrder.map(id => String(id)) : []
        if (items.length < 2
            || itemIds.some(id => !id)
            || uniqueItemIds.size !== items.length
            || items.some(item => !String(item?.text ?? '').trim())
            || correctOrder.length !== items.length
            || new Set(correctOrder).size !== items.length
            || correctOrder.some(id => !uniqueItemIds.has(id))) {
            flag = true
        }
    }
    return flag
}
function normalizeAcceptedAnswerKey(value) {
    return String(value ?? '')
        .trim()
        .replace(/\s+/g, '')
        .toLowerCase()
}
vueData.isCheckAllGroupFullQuiz = isCheckAllGroupFullQuiz
vueData.isCheckGroupHasAnswerQuestionNotChoose = isCheckGroupHasAnswerQuestionNotChoose
vueData.isCheckAnswerQuestionNotChoose = isCheckAnswerQuestionNotChoose
function normalizeNumberInput(value) {
    if (value === null || value === undefined) return 0
    const normalized = String(value).replace(',', '.')
    const num = parseFloat(normalized)
    return isNaN(num) ? 0 : num
}
vueData.normalizeNumberInput = normalizeNumberInput
function isAutoGradable(type) {
    // QUIZ_ORDERING có đáp án chuẩn nên thuộc nhóm quiz và được phép chấm tự động.
    return String(type || '').startsWith('QUIZ_')
}
vueData.isAutoGradable = isAutoGradable
// Chấm QUIZ_ORDERING theo từng vị trí: tổng điểm câu hỏi được chia đều cho số item.
// Tính động từ question.points để khi giáo viên đổi tổng điểm, điểm mỗi item không bị stale.
function getOrderingItemScore(question) {
    const items = Array.isArray(question?.config?.items) ? question.config.items : []
    const totalPoints = normalizeNumberInput(question?.points)
    return items.length > 0 ? totalPoints / items.length : 0
}
function getOrderingScore(question, submittedOrder) {
    const items = Array.isArray(question?.config?.items) ? question.config.items : []
    const itemIds = items.map(item => String(item?.id ?? ''))
    const expectedOrder = Array.isArray(question?.config?.correctOrder) && question.config.correctOrder.length
        ? question.config.correctOrder.map(id => String(id))
        : itemIds
    const actualOrder = Array.isArray(submittedOrder) ? submittedOrder.map(id => String(id)) : []
    const pointsPerItem = expectedOrder.length > 0 ? normalizeNumberInput(question?.points) / expectedOrder.length : 0
    let correctCount = 0
    for (let index = 0; index < expectedOrder.length; index += 1) {
        if (actualOrder[index] === expectedOrder[index]) correctCount += 1
    }
    return {
        correctCount,
        totalItems: expectedOrder.length,
        pointsPerItem,
        score: correctCount * pointsPerItem,
        totalPoints: expectedOrder.length * pointsPerItem,
        isCorrect: expectedOrder.length > 0 && correctCount === expectedOrder.length,
    }
}
vueData.getOrderingItemScore = getOrderingItemScore
vueData.getOrderingScore = getOrderingScore
const _defaultMedia = () => ({
    type: 'YOUTUBE',
    sourceYT: { id: '', name: '', source: '' },
    sourceRecord: { id: '', name: '', source: '' },
    sourceFiles: { file: [], image: [] }
})
function buildNewQuestion(componentInfo, ordinalNumber) {
    const q = {
        id: `q_${crypto.randomUUID()}`,
        type: componentInfo.type,
        label: componentInfo.label,
        skills: [],
        ordinalNumber,
        points: 1.0,
        gradingType: 'auto',
        config: {
            media: _defaultMedia(),
            isAdvanced: false,
            questionText: ''
        }
    }
    switch (componentInfo.type) {
        case 'QUIZ_SINGLE_CHOICE':
            q.config.options = [
                { id: crypto.randomUUID(), text: '' }, { id: crypto.randomUUID(), text: '' },
                { id: crypto.randomUUID(), text: '' }, { id: crypto.randomUUID(), text: '' }
            ]
            q.config.correctAnswer = null
            break
        case 'QUIZ_MULTIPLE_CHOICE':
            q.config.options = [
                { id: crypto.randomUUID(), text: '' }, { id: crypto.randomUUID(), text: '' },
                { id: crypto.randomUUID(), text: '' }, { id: crypto.randomUUID(), text: '' }
            ]
            q.config.correctAnswers = []
            q.config.scoringMode = 'equal'
            break
        case 'QUIZ_TRUE_FALSE':
            q.config.statement = 'Mệnh đề cần xác định đúng/sai.'
            q.config.correctAnswer = true
            break
        case 'QUIZ_MULTIPLE_TRUE_FALSE':
            q.config.options = [{ id: crypto.randomUUID(), text: '', correctAnswer: null, inCorrectAnswer: null }]
            q.config.scoringMode = 'equal'
            break
        case 'QUIZ_FILL_IN_BLANK':
            q.config.parts = [
                { type: 'text', value: 'Điền vào ' },
                { type: 'blank', id: `blank_${crypto.randomUUID()}`, acceptedAnswers: ['chỗ trống'] },
                { type: 'text', value: ' này.' }
            ]
            break
        case 'QUIZ_MATCHING':
            q.config.columnA = []
            q.config.columnB = []
            q.config.correctPairs = []
            break
        case 'QUIZ_ORDERING':
            q.config.items = [
                { id: crypto.randomUUID(), text: '' },
                { id: crypto.randomUUID(), text: '' }
            ]
            q.config.correctOrder = q.config.items.map(item => item.id)
            q.config.scoringMode = 'equal'
            break
        case 'ESSAY':
        case 'SHORT_ANSWER':
            // Câu chấm tay vẫn cần đáp án tham khảo để giáo viên đối chiếu khi chấm bài.
            q.config.referenceAnswer = ''
        case 'FILE_UPLOAD':
        case 'AUDIO_RESPONSE':
            q.gradingType = 'manual'
            break
    }
    return q
}
vueData.buildNewQuestion = buildNewQuestion