// Chuẩn hóa JSON không tin cậy từ DataJson/ConfigJson trước khi đưa vào source contract.
function safeParseJson(value, fallback) {
	if (value && typeof value === 'object') return value
	if (typeof value !== 'string' || !value.trim()) return fallback
	try {
		return JSON.parse(value)
	} catch (error) {
		return fallback
	}
}
// Chuẩn hóa tài liệu/câu hỏi về contract chung; mapper target nằm tại module nhận.
function normalizeSource(input) {
	const source = input || {}
	return {
		sourceType: source.sourceType || null,
		sourceId: source.sourceId ?? null,
		sourceRefType: source.sourceRefType || null,
		title: source.title || '',
		contentType: source.contentType || null,
		khoiId: source.khoiId ?? null,
		monHocId: source.monHocId ?? null,
		ownerUserId: source.ownerUserId || null,
		visibilityScope: source.visibilityScope || 'PRIVATE',
		status: source.status || 'DRAFT',
		versionNo: Number(source.versionNo || 1),
		sourceUpdatedAt: source.sourceUpdatedAt || null,
		payload: safeParseJson(source.payload, {}),
		media: Array.isArray(source.media) ? source.media : [],
		warnings: Array.isArray(source.warnings) ? source.warnings : [],
		errors: Array.isArray(source.errors) ? source.errors : []
	}
}
// Kiểm tra source và context trước khi module đích chạy mapper riêng của nó.
function validateSource(source, context) {
	const normalized = normalizeSource(source)
	const errors = []
	const warnings = []
	if (!normalized.sourceType) errors.push('Thiếu SourceType.')
	if (normalized.sourceId === null || normalized.sourceId === undefined) errors.push('Thiếu SourceID.')
	if (!normalized.title.trim()) errors.push('Thiếu tiêu đề nguồn.')
	if (context && context.khoiId && normalized.khoiId && Number(context.khoiId) !== Number(normalized.khoiId)) {
		warnings.push('Nguồn khác Khối đang được chọn.')
	}
	if (context && context.monHocId && normalized.monHocId && String(context.monHocId) !== String(normalized.monHocId)) {
		warnings.push('Nguồn khác Môn đang được chọn.')
	}
	return { source: normalized, errors, warnings }
}
// var global giúp các module FUI khác dùng LMSContentCore mà không cần IIFE tự chạy.
var LMSContentCore = {
	version: '0.1.0',
	safeParseJson: safeParseJson,
	normalizeSource: normalizeSource,
	validateSource: validateSource
}