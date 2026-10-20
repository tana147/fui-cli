/**
 * Chuẩn hóa danh sách lớp trả về từ Lop_Get_ByKhoiID.
 * API dùng chung có thể trả cả tblLop và tblNhom; màn hình log điểm chỉ hiển thị
 * lớp thật trong tblLop, đồng thời gom lớp tổ hợp cấp 3 theo quy tắc của so-gvcn.
 */
function buildLogDiemClassOptions(rows, capID) {
	const map = new Map()
	const isCap3 = Number(capID) === 3
	;(Array.isArray(rows) ? rows : []).forEach(row => {
		if (!row || !row.LopID) return
		// IsNhom=1 là dòng từ tblNhom được API ghép vào; không đưa nhóm/DI vào dropdown lớp.
		if (row.IsNhom === true || Number(row.IsNhom) === 1) return
		const lopID = String(row.LopID).trim()
		const tenLop = String(row.TenLop || lopID).trim()
		const isLopToHop = isCap3 && (row.IsLopToHop === true || Number(row.IsLopToHop) === 1)
		const tenLopGoc = isLopToHop ? (tenLop.replace(/[0-9]+$/, '') || tenLop) : tenLop
		const key = isLopToHop ? String(row.KhoiID || '') + '|' + tenLopGoc : lopID
		const item = map.get(key) || {
			LopID: row.LopID,
			LopIDs: [],
			TenLop: tenLopGoc,
			TenLopThanhVien: [],
			KhoiID: row.KhoiID,
			GVCN: row.GVCN,
			IsLopToHop: isLopToHop
		}
		if (!item.LopIDs.some(id => String(id) === lopID)) item.LopIDs.push(row.LopID)
		if (!item.TenLopThanhVien.some(name => name === tenLop)) item.TenLopThanhVien.push(tenLop)
		map.set(key, item)
	})
	return [...map.values()]
		.map(item => {
			const members = [...item.TenLopThanhVien].sort((a, b) => String(a).localeCompare(String(b), 'vi', { numeric: true }))
			return {
				...item,
				TenLopThanhVien: members,
				TenLop: members.length > 1 ? item.TenLop + ' (' + members.join(', ') + ')' : item.TenLop
			}
		})
		.sort((a, b) => {
			if (Number(a.KhoiID || 0) !== Number(b.KhoiID || 0)) return Number(a.KhoiID || 0) - Number(b.KhoiID || 0)
			return String(a.TenLop).localeCompare(String(b.TenLop), 'vi', { numeric: true })
		})
}
/**
 * Lớp gộp phải truyền toàn bộ lớp thành viên xuống SP log điểm,
 * còn lớp đơn vẫn giữ nguyên một mã để tương thích với cách tra cứu hiện tại.
 */
function getLogDiemLopIDs(item) {
	if (!item) return null
	const ids = (item.LopIDs || [item.LopID])
		.filter(id => id !== undefined && id !== null && String(id).trim() !== '')
		.map(id => String(id).trim())
	return ids.length ? [...new Set(ids)].join(',') : null
}
// module.json có fallback inline để module_simulate không phụ thuộc việc sandbox nạp script.js.