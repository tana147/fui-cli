function showModuleSnackbarHB(message, color = 'warning') {
	if (vueData.snackbarRef?.value?.showSnackbar) {
		vueData.snackbarRef.value.showSnackbar({ message, color })
		return
	}
	if (window.Vue && Vue.$toast) {
		if (color === 'success') return Vue.$toast.success(message, { position: 'top' })
		if (color === 'error') return Vue.$toast.error(message, { position: 'top' })
		return Vue.$toast.warning(message, { position: 'top' })
	}
	alert(message)
}
function normalizeHocBongText(value) {
	return String(value ?? '')
		.replaceAll('KỲ', 'KÌ')
		.replaceAll('Kỳ', 'Kì')
		.replaceAll('kỳ', 'kì')
}
// Khi tạo phong trào mới, điền sẵn bộ giải phổ biến; người dùng vẫn có thể sửa hoặc xóa trước khi lưu.
const DEFAULT_PHONG_TRAO_CAC_GIAI = 'Giải Nhất, Giải Nhì, Giải Ba'
// Các dòng trên giấy khen được lưu theo thứ tự và mã dòng, không khóa vào đúng ba cột semantic cũ.
// Ba mã tương thích này giúp dữ liệu/API in hiện tại vẫn đọc được Dòng 1/2/3 trong khi có thể mở rộng thêm dòng mới.
const DEFAULT_PHONG_TRAO_DONG = [
	{ ThuTuDong: 1, TenDong: 'Dòng 1', MaDong: 'DANH_HIEU_VI', NgonNgu: 'VI', NoiDung: '', KieuDuLieu: 'text', BatBuoc: 1, Enable: 1 },
	{ ThuTuDong: 2, TenDong: 'Dòng 2', MaDong: 'DANH_HIEU_EN', NgonNgu: 'EN', NoiDung: '', KieuDuLieu: 'text', BatBuoc: 0, Enable: 1 },
	{ ThuTuDong: 3, TenDong: 'Dòng 3', MaDong: 'NAM_HOC', NgonNgu: 'ALL', NoiDung: '', KieuDuLieu: 'school-year', BatBuoc: 0, Enable: 1 }
]
function normalizePhongTraoDong(item, index) {
	const thuTuDong = Number(item?.ThuTuDong) || index + 1
	const rawEnable = item?.Enable
	return {
		DongID: Number(item?.DongID) || 0,
		ThuTuDong: thuTuDong,
		TenDong: String(item?.TenDong || `Dòng ${thuTuDong}`).trim(),
		MaDong: String(item?.MaDong || '').trim(),
		NgonNgu: String(item?.NgonNgu || 'ALL').trim().toUpperCase(),
		NoiDung: String(item?.NoiDung ?? ''),
		KieuDuLieu: String(item?.KieuDuLieu || 'text').trim(),
		BatBuoc: item?.BatBuoc === true || Number(item?.BatBuoc) === 1,
		Enable: rawEnable === false || Number(rawEnable) === 0 ? false : true
	}
}
function parsePhongTraoDongJson(value) {
	if (Array.isArray(value)) return value.map(normalizePhongTraoDong)
	if (typeof value !== 'string' || !value.trim()) return null
	try {
		const parsed = JSON.parse(value)
		return Array.isArray(parsed) ? parsed.map(normalizePhongTraoDong) : null
	} catch (error) {
		console.warn('Không đọc được DongJson của phong trào:', error)
		return null
	}
}
function getMasterPhongTraoDongs(master) {
	// DongJson='[]' là trạng thái người dùng đã xóa hết dòng; chỉ fallback khi API cũ chưa có field dynamic.
	const parsed = parsePhongTraoDongJson(master?.DongJson ?? master?.DongNoiDung)
	if (parsed !== null) return parsed.filter(row => row.Enable !== false).sort((a, b) => a.ThuTuDong - b.ThuTuDong)
	return [
		normalizePhongTraoDong({ ThuTuDong: 1, TenDong: 'Dòng 1', MaDong: 'DANH_HIEU_VI', NgonNgu: 'VI', NoiDung: master?.DanhHieu_VI || '', BatBuoc: 1 }, 0),
		normalizePhongTraoDong({ ThuTuDong: 2, TenDong: 'Dòng 2', MaDong: 'DANH_HIEU_EN', NgonNgu: 'EN', NoiDung: master?.DanhHieu_EN || '' }, 1),
		normalizePhongTraoDong({ ThuTuDong: 3, TenDong: 'Dòng 3', MaDong: 'NAM_HOC', NgonNgu: 'ALL', NoiDung: master?.NamHoc ?? '' }, 2)
	]
}
function createDefaultPhongTraoDongs() {
	return DEFAULT_PHONG_TRAO_DONG.map(row => ({ ...row, NoiDung: row.MaDong === 'NAM_HOC' ? getPhongTraoSchoolYearLabel() : '' }))
}
function normalizeMasterPhongTraoDongs(rows) {
	return (rows || []).map((row, index) => ({
		...normalizePhongTraoDong(row, index),
		ThuTuDong: index + 1,
		TenDong: String(row?.TenDong || `Dòng ${index + 1}`).trim() || `Dòng ${index + 1}`
	}))
}
function getLegacyPhongTraoLines(rows) {
	const findLine = (code, order) => rows.find(row => row.MaDong === code) || rows.find(row => row.ThuTuDong === order)
	return {
		DanhHieu_VI: String(findLine('DANH_HIEU_VI', 1)?.NoiDung || ''),
		DanhHieu_EN: String(findLine('DANH_HIEU_EN', 2)?.NoiDung || ''),
		NamHoc: String(findLine('NAM_HOC', 3)?.NoiDung || '')
	}
}
// Quyền màn hình dùng SystemRight thống nhất của LMS: 1=GVCN, 3=BGH, 5=Tổ trưởng, 9=Admin.
// UI chỉ là lớp bảo vệ trải nghiệm; các API vẫn phải nhận sys_UserID từ session để kiểm tra quyền ở server.
function getHocBongSystemRight() {
	// FUI production thường đặt quyền ở vueData.user; preview và một số shell cũ có thể
	// truyền qua userInfo/UserInfo. Đọc lần lượt các nguồn này để cùng một rule chạy ổn định
	// khi mở module thật, mở bằng deep-link và khi kiểm thử component độc lập.
	const runtimeVueData = typeof window !== 'undefined' ? window.vueData : null
	const userCandidates = [
		vueData.user,
		vueData.userInfo,
		vueData.UserInfo,
		runtimeVueData?.user,
		runtimeVueData?.userInfo,
		typeof window !== 'undefined' ? window.userInfo : null,
		typeof window !== 'undefined' ? window.user : null,
	].filter(Boolean)
	let raw
	for (const user of userCandidates) {
		raw = user.SystemRight ?? user.systemRight
		if (raw !== undefined && raw !== null && raw !== '') break
	}
	raw = raw ?? vueData.SystemRight ?? vueData.systemRight ?? runtimeVueData?.SystemRight ?? runtimeVueData?.systemRight
	if (Array.isArray(raw)) return Number(raw[0]) || 9
	return raw === undefined || raw === null || raw === '' ? 9 : (Number(raw) || 9)
}
function isGVCNHocBong() {
	return getHocBongSystemRight() === 1
}
function canViewHocBongTab() {
	return !isGVCNHocBong()
}
function canManagePhongTraoDetail(master = vueData.selectedPhongTrao) {
	if (!master) return false
	const loaiMau = Number(master?.LoaiMau) || 1
	const systemRight = getHocBongSystemRight()
	// Admin (9), BGH (3), Tổ trưởng (5) quản trị được tất cả các mẫu (1, 2, 3, 4)
	if ([3, 5, 9].includes(systemRight)) return true
	// GVCN (1) quản lý Mẫu 3
	if (systemRight === 1 && loaiMau === 3) return true
	return false
}
function canManagePhongTraoMaster() {
	return [3, 5, 9].includes(getHocBongSystemRight())
}
function filterPhongTraoMasterByRole(list) {
	if (!isGVCNHocBong()) return list
	// GVCN chỉ nhìn thấy các phong trào Mẫu 3 được giao thực hiện, không nhìn thấy danh sách Học bổng/quản trị khác.
	return (list || []).filter(item => Number(item?.LoaiMau) === 3)
}
function syncModuleRoleState() {
	vueData.canViewHocBong = canViewHocBongTab()
	if (vueData.canViewHocBong === false && vueData.activeTab === 'HOC_BONG') {
		vueData.activeTab = 'PHONG_TRAO'
	}
	vueData.canManageSelectedPhongTrao = canManagePhongTraoDetail()
}
function getNienKhoaCurrent() {
	const val = vueData.NienKhoa || vueData.NienKhoaItem?.NienKhoa || (window.vueData && (window.vueData.NienKhoa || window.vueData.NienKhoaItem?.NienKhoa)) || 2026
	const num = Number(val)
	return (num && !isNaN(num)) ? num : 2026
}
function getPhongTraoSchoolYearLabel() {
	const startYear = getNienKhoaCurrent()
	return `Năm học/ School Year ${startYear} - ${startYear + 1}`
}
function getHocBongUserId() {
	const runtimeVueData = typeof window !== 'undefined' ? window.vueData : null
	const user = vueData.user || vueData.userInfo || vueData.UserInfo || runtimeVueData?.user || runtimeVueData?.userInfo
	return String(user?.UserID || user?.GiaoVienID || user?.TeacherID || '').trim()
}
function unwrapHocBongApiRows(response) {
	let data = response
	if (data && typeof data === 'object' && !Array.isArray(data)) {
		data = data.data ?? data.Data ?? data.result ?? data.Result ?? data.rows ?? data.Rows ?? data.Table ?? data
	}
	if (Array.isArray(data) && data.length > 0 && Array.isArray(data[0])) data = data[0]
	return Array.isArray(data) ? data : []
}
function normalizePhongTraoClassRow(row) {
	const tenLop = String(row?.TenLop || '').trim()
	return {
		...row,
		TenLop: tenLop,
		title: row?.TenLopHienThi || tenLop,
		value: tenLop,
		KhoiID: row?.KhoiID,
		LopID: row?.LopID,
		NienKhoa: row?.NienKhoa ?? getNienKhoaCurrent()
	}
}
async function loadGVCNPhongTraoScope() {
	if (!isGVCNHocBong()) return { classes: [], students: [] }
	const nienKhoa = getNienKhoaCurrent()
	const teacherId = getHocBongUserId()
	if (!teacherId) throw new Error('Không xác định được mã giáo viên đăng nhập')
	// tblLop là nguồn xác định quyền chủ nhiệm của GVCN trong đúng niên khóa; không dùng danh sách lớp toàn trường.
	const classResponse = await ajaxCALLPromise('lms/Lop_Get_ByNienKhoa', {
		NienKhoa: nienKhoa,
		SYS_USERID: teacherId
	})
	const classes = unwrapHocBongApiRows(classResponse)
		.filter(row => String(row?.NienKhoa ?? nienKhoa) === String(nienKhoa))
		.filter(row => String(row?.GVCN || '').trim().toLowerCase() === teacherId.toLowerCase())
		.filter(row => Number(row?.LopID) > 0)
		.map(normalizePhongTraoClassRow)
	const uniqueClasses = [...new Map(classes.map(row => [String(row.LopID), row])).values()]
	vueData.DSAllLop = uniqueClasses
	vueData.DSFilteredLop = uniqueClasses
	// tblHocSinhLop được đọc theo từng LopID + NienKhoa để không lẫn học sinh của lớp/niên khóa khác.
	const studentResponses = await Promise.all(uniqueClasses.map(row => ajaxCALLPromise('lms/HocSinhLop_Get_ByLopID', {
		LopID: row.LopID,
		MonHocID: 0,
		HocLieuID: 0,
		NienKhoa: nienKhoa
	})))
	const students = studentResponses.flatMap((response, index) => {
		const classRow = uniqueClasses[index]
		return unwrapHocBongApiRows(response).map(student => {
			const hoTen = student.HoTen || `${student.Ho || ''} ${student.Ten || ''}`.trim()
			const tenLop = student.TenLop || classRow.TenLop
			const label = `${hoTen} - ${tenLop} (MSHS ${student.HocSinhID || ''})`
			return {
				...student,
				HoTen: hoTen,
				TenLop: tenLop,
				LopID: student.LopID || classRow.LopID,
				KhoiID: student.KhoiID || classRow.KhoiID,
				NienKhoa: student.NienKhoa || nienKhoa,
				Title: label,
				title: label,
				value: student.HocSinhID
			}
		})
	})
	vueData.DSAllHocSinh = [...new Map(students.filter(row => Number(row.HocSinhID) > 0).map(row => [String(row.HocSinhID), row])).values()]
	vueData.DSFilteredHocSinh = vueData.DSAllHocSinh
	vueData.GVCNPhongTraoScopeKey = `${teacherId}:${nienKhoa}`
	return { classes: uniqueClasses, students: vueData.DSAllHocSinh }
}
async function ensureGVCNPhongTraoScope() {
	if (!isGVCNHocBong()) return
	const key = `${getHocBongUserId()}:${getNienKhoaCurrent()}`
	if (vueData.GVCNPhongTraoScopeKey === key) return
	await loadGVCNPhongTraoScope()
}
function filterPhongTraoDetailByRole(list) {
	if (!isGVCNHocBong()) return list
	const allowedStudentIds = new Set((vueData.DSAllHocSinh || []).map(row => String(row.HocSinhID)))
	const allowedClassIds = new Set((vueData.DSAllLop || []).map(row => String(row.LopID)))
	const allowedClassNames = new Set((vueData.DSAllLop || []).map(row => String(row.TenLop || '').trim().toLowerCase()).filter(Boolean))
	// GVCN chỉ được xem các dòng thuộc học sinh/lớp của mình; BGH, Admin, Tổ trưởng không đi qua nhánh lọc này.
	return (list || []).filter(row => {
		if (Number(row?.HocSinhID) > 0) return allowedStudentIds.has(String(row.HocSinhID))
		if (Number(row?.LopID) > 0) return allowedClassIds.has(String(row.LopID))
		return allowedClassNames.has(String(row?.TenLop || '').trim().toLowerCase())
	})
}
function normalizePhongTraoSchoolYear(item) {
	if (!item || typeof item !== 'object') return item
	// Chỉ bổ sung năm học mặc định khi API không trả field; chuỗi rỗng là giá trị hợp lệ khi người dùng chủ động xóa Dòng 3.
	if (item.NamHoc === null || item.NamHoc === undefined) {
		return { ...item, NamHoc: getPhongTraoSchoolYearLabel() }
	}
	return item
}
function getDeletedCount(response) {
	const queue = [response]
	const visited = new Set()
	while (queue.length) {
		const value = queue.shift()
		if (!value || (typeof value !== 'object' && !Array.isArray(value)) || visited.has(value)) continue
		visited.add(value)
		if (Array.isArray(value)) {
			value.forEach(item => queue.push(item))
			continue
		}
		const raw = value.Deleted ?? value['Deleted = @@ROWCOUNT']
		if (raw !== undefined && raw !== null && raw !== '') return Number(raw)
		;['data', 'Data', 'result', 'Result'].forEach(key => {
			if (value[key] !== undefined) queue.push(value[key])
		})
	}
	return null
}
function getPrizeNames(master) {
	return String(master?.CacGiai_VI || '')
		.split(',')
		.map(value => value.trim())
		.filter(Boolean)
}
function getPrizeVietnameseContent(content, prize) {
	const text = String(content || '')
	const prizeText = String(prize || '').trim()
	// Dấu "-" chỉ là dòng đại diện khi phong trào không chia giải, không được đưa vào nội dung giấy khen.
	if (!prizeText || prizeText === '-') return text
	const award = prizeText.replace(/^Giải\s+/, '')
	if (text.startsWith('Xếp hạng')) return `Xếp hạng ${award} trong phong trào thi đua`
	if (text.startsWith('Đạt giải')) return text.replace(/^Đạt giải(?:\s+(?:Nhất|Nhì|Ba|Khuyến khích))?/, `Đạt giải ${award}`)
	return `${prizeText} - ${text}`
}
function getPrizeEnglishContent(content, prize) {
	const awards = { 'Giải Nhất': 'First Place', 'Giải Nhì': 'Second Place', 'Giải Ba': 'Third Place', 'Giải Khuyến khích': 'Consolation Award' }
	const text = String(content || '')
	const prizeText = String(prize || '').trim()
	// Dấu "-" chỉ là dòng đại diện khi phong trào không chia giải, không được đưa vào nội dung giấy khen.
	if (!prizeText || prizeText === '-') return text
	const award = awards[prizeText] || prizeText
	if (text.startsWith('In recognition')) return `In recognition of the attainment of ${award} in Overall Class Performance`
	if (text.startsWith('For achieving')) return text.replace(/^For achieving(?:\s+(?:First|Second|Third) Place|\s+Consolation Prize)?/, `For achieving ${award}`)
	if (text.startsWith('In the')) return `${award.replace('Place', 'Prize')} ${text}`
	return `${award} - ${text}`
}
function ensureSelectedPrize(master) {
	const prizeNames = getPrizeNames(master)
	if (!prizeNames.includes(vueData.selectedPrizeName)) {
		vueData.selectedPrizeName = prizeNames[0] || ''
	}
}
function getSelectedPrizeContent(master) {
	const prizeName = vueData.selectedPrizeName || getPrizeNames(master)[0] || ''
	const legacyLines = getLegacyPhongTraoLines(getMasterPhongTraoDongs(master))
	return {
		TenGiai_VI: prizeName,
		DanhHieu_VI: getPrizeVietnameseContent(legacyLines.DanhHieu_VI, prizeName),
		DanhHieu_EN: getPrizeEnglishContent(legacyLines.DanhHieu_EN, prizeName)
	}
}
function matchesSelectedPrize(detail, prizeName) {
	if (!prizeName) return true
	const keywords = {
		'Giải Nhất': 'Nhất',
		'Giải Nhì': 'Nhì',
		'Giải Ba': 'Ba',
		'Giải Khuyến khích': 'Khuyến khích'
	}
	const directPrize = detail?.TenGiai_VI || detail?.GiaiDatDuoc || detail?.TenGiai || ''
	const content = detail?.DanhHieu_VI || ''
	return String(directPrize).includes(prizeName) || String(content).includes(keywords[prizeName] || prizeName)
}
function filterPhongTraoDetailsByPrize(details) {
	if (!Array.isArray(details) || !vueData.selectedPrizeName) return details || []
	return details.filter(detail => matchesSelectedPrize(detail, vueData.selectedPrizeName))
}
function filterRecentlyDeletedPhongTraoDetails(details) {
	const deletedIds = new Set((vueData.deletedPhongTraoDetailIds || []).map(Number))
	return (details || []).filter(detail => !deletedIds.has(Number(detail?.ChiTietID)))
}
// ==================== TAB 1: HỌC BỔNG (NGUYÊN TRẠNG 100%) ====================
function renderDSHocBong() {
	vueData.columnHeader = [
		{ title: 'STT', name: 'STT', width: 50, readOnly: true },
		{ title: 'Mã HS', name: 'HocSinhID', width: 90, readOnly: true },
		{ title: 'Họ và tên', name: 'HoTen', width: 220, readOnly: true, align: 'left' },
		{ title: 'Lớp', name: 'TenLop', width: 70, readOnly: true },
		{ title: 'Khối', name: 'KhoiID', width: 60, readOnly: true },
		{ title: 'Mức học bổng', name: 'MucHocBong', width: 200 },
		{ title: 'Nhóm (VI)', name: 'TieuChi_VI', width: 340 },
		{ title: 'Nhóm (EN)', name: 'TieuChi_EN', width: 340 },
		{ title: 'Số quyết định', name: 'SoQuyetDinh', width: 110 },
		{ title: 'Vào sổ (STT)', name: 'VaoSo', width: 100, type: 'numeric' },
		{ title: 'Ngày cấp (VI)', name: 'NgayCap_VI', width: 200 },
		{ title: 'Ngày cấp (EN)', name: 'NgayCap_EN', width: 160 },
		{ title: 'Đã in', name: 'Is_DaIn', width: 70, readOnly: true }
	]
	vueData.DSHocSinh = (vueData.DSHocBong || []).map((x, index) => {
		x.Title = `${x.HoTen || ''} - ${x.TenLop || ''} (MSHS ${x.HocSinhID || ''})`
		return [
			index + 1,
			x.HocSinhID,
			normalizeHocBongText(x.HoTen),
			normalizeHocBongText(x.TenLop),
			x.KhoiID,
			normalizeHocBongText(x.MucHocBong),
			normalizeHocBongText(x.TieuChi_VI),
			normalizeHocBongText(x.TieuChi_EN),
			normalizeHocBongText(x.SoQuyetDinh),
			x.VaoSo ?? (index + 1),
			normalizeHocBongText(x.NgayCap_VI),
			normalizeHocBongText(x.NgayCap_EN),
			x.Is_DaIn ? 'Có' : 'Không'
		]
	})
	vueData.DSHocSinhChange = []
	vueData.keyComp++
}
function renderDSHocSinhChange() {
	if (vueData.activeTab === 'PHONG_TRAO') {
		return (vueData.DSHocSinhChange || []).map(id => {
			const ct = (vueData.DSHocBongDetail || []).find(x => String(x.ChiTietID) === String(id))
			return {
				HocSinhID: id,
				HoTen: ct?.HoTen || ct?.DanhHieu_VI || `Khen thưởng #${id}`,
				TenLop: ct?.TenLop || ''
			}
		})
	}
	return (vueData.DSHocSinhChange || []).map(hocSinhID => {
		const hs = (vueData.DSHocBong || []).find(x => String(x.HocSinhID) === String(hocSinhID))
		return {
			HocSinhID: hocSinhID,
			HoTen: hs?.HoTen || '',
			TenLop: hs?.TenLop || ''
		}
	})
}
function onExportExcel() {
	if (vueData.activeTab === 'PHONG_TRAO') return onExportExcelPTDetail()
	if (!vueData.DSHocSinh || !vueData.DSHocSinh.length) return
	const headerRow = vueData.columnHeader.map(c => c.title)
	const aoa = [headerRow, ...vueData.DSHocSinh]
	const worksheet = XLSX.utils.aoa_to_sheet(aoa)
	const workbook = XLSX.utils.book_new()
	XLSX.utils.book_append_sheet(workbook, worksheet, 'HocBong')
	XLSX.writeFile(workbook, `DanhSachHocBong_HK${vueData.Semester?.value}_${getNienKhoaCurrent()}.xlsx`)
}
function onSave() {
	if (vueData.activeTab === 'PHONG_TRAO') return onSavePTDetail()
	if (!vueData.DSHocSinhChange || !vueData.DSHocSinhChange.length) {
		showModuleSnackbarHB('Không có thay đổi nào để lưu', 'warning')
		return
	}
	vueData.IsShowDialogConfirm = true
}
async function confirmSaveHocBong() {
	if (vueData.activeTab === 'PHONG_TRAO') return confirmSavePTDetail()
	vueData.isLoadingSave = true
	try {
		const instance = Array.isArray(vueData.instance) ? vueData.instance[0] : vueData.instance
		const rows = instance.getData()
		const keys = vueData.columnHeader.map(c => c.name)
		const objs = rows.map(r => {
			const o = {}
			keys.forEach((k, i) => { o[k] = r[i] })
			return o
		})
		const changedIds = new Set((vueData.DSHocSinhChange || []).map(String))
		const payload = objs
			.filter(o => changedIds.has(String(o.HocSinhID)))
			.map(o => {
				const orig = (vueData.DSHocBong || []).find(x => String(x.HocSinhID) === String(o.HocSinhID))
				return {
					HocBongCertID: orig?.HocBongCertID,
					MucHocBong: normalizeHocBongText(o.MucHocBong),
					TieuChi_VI: normalizeHocBongText(o.TieuChi_VI),
					TieuChi_EN: normalizeHocBongText(o.TieuChi_EN),
					SoQuyetDinh: normalizeHocBongText(o.SoQuyetDinh),
					VaoSo: Number(o.VaoSo) || null,
					NgayCap_VI: normalizeHocBongText(o.NgayCap_VI),
					NgayCap_EN: normalizeHocBongText(o.NgayCap_EN)
				}
			})
		await ajaxCALLPromise('lms/HocBongCert_Upd_JSON', { JsonData: JSON.stringify(payload) })
		payload.forEach(p => {
			const orig = (vueData.DSHocBong || []).find(x => x.HocBongCertID === p.HocBongCertID)
			if (orig) Object.assign(orig, p)
		})
		renderDSHocBong()
		vueData.IsShowDialogConfirm = false
		showModuleSnackbarHB('Đã lưu thành công', 'success')
	} catch (error) {
		showModuleSnackbarHB('Lưu thất bại: ' + (error?.message || ''), 'error')
	} finally {
		vueData.isLoadingSave = false
	}
}
async function exportGiayChungNhanHocBong() {
	if (!vueData.DSHocBong || !vueData.DSHocBong.length) {
		showModuleSnackbarHB('Không có dữ liệu để in', 'warning')
		return
	}
	vueData.isLoadingPrint = true
	const hocKyText = vueData.Semester?.value === 2 ? 'II' : 'I'
	const certs = vueData.DSHocBong.map(x => {
		return {
			khenTang_Vi: 'Khen tặng học sinh',
			khenTang_En: 'This certificate is proudly presented to',
			hoTen: String(x.HoTen || '').toUpperCase(),
			lop: x.TenLop || '',
			hocBong_Vi: `Đạt học bổng ${x.MucHocBong || ''} Học kì ${hocKyText} khối ${x.KhoiID}`,
			hocBong_En: `Awarded ${x.MucHocBong || ''} Scholarship for Semester ${hocKyText}, Grade ${x.KhoiID}`,
			nhom_Vi: x.TieuChi_VI || '',
			nhom_En: x.TieuChi_EN || '',
			namHoc_Vi: '',
			namHoc_En: '',
			ngayThangNam_Vi: x.NgayCap_VI || '',
			ngayThangNam_En: x.NgayCap_EN || '',
			soQuyetDinh: `${x.SoQuyetDinh || ''}/QĐ-SNLH.NO:${x.VaoSo ?? ''}`,
			tenHieuTruong: 'Hoàng Thị Diễm Trang'
		}
	})
	try {
		const response = await fetch('https://gencert.iotsoftvn.com/api/cert-generators/multi-pdf-scholarship', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ certs })
		})
		if (!response.ok) throw new Error('HTTP ' + response.status)
		const blob = await response.blob()
		const url = window.URL.createObjectURL(blob)
		const link = document.createElement('a')
		link.href = url
		link.download = 'DanhSachGiayChungNhanHocBong.pdf'
		document.body.appendChild(link)
		link.click()
		link.remove()
	} catch (error) {
		showModuleSnackbarHB('In giấy chứng nhận thất bại: ' + (error?.message || ''), 'error')
	} finally {
		vueData.isLoadingPrint = false
	}
}
async function openAddHocSinh() {
	vueData.AddHocSinhSelected = null
	vueData.AddMucHocBong = '25% học phí học kì I'
	vueData.IsShowDialogAdd = true
	if (!vueData.DSAllHocSinh || vueData.DSAllHocSinh.length === 0) {
		vueData.isLoadingAddHocSinh = true
		try {
			const res = await ajaxCALLPromise('lms/HocSinh_Get', { NienKhoa: getNienKhoaCurrent() })
			let data = res
			if (data && typeof data === 'object' && !Array.isArray(data)) {
				if (Array.isArray(data.data)) data = data.data
				else if (Array.isArray(data.result)) data = data.result
				else if (Array.isArray(data.rows)) data = data.rows
				else data = []
			}
			if (Array.isArray(data) && data.length > 0 && Array.isArray(data[0])) {
				data = data[0]
			}
			let list = Array.isArray(data) ? data : []
			const selectedKhoiID = vueData.KhoiItem?.value ?? 0
			if (selectedKhoiID > 0) {
				list = list.filter(x => {
					if (x.KhoiID) return Number(x.KhoiID) === selectedKhoiID
					const lopStr = String(x.TenLop || '')
					const numMatch = lopStr.match(/^0?(\d+)/)
					return numMatch ? Number(numMatch[1]) === selectedKhoiID : true
				})
			}
			vueData.DSAllHocSinh = list.map(x => {
				const label = `${x.HoTen || ((x.Ho || '') + ' ' + (x.Ten || ''))} - ${x.TenLop || ''} (MSHS ${x.HocSinhID || ''})`
				return { ...x, Title: label, title: label }
			})
		} catch (error) {
			console.error(error)
		} finally {
			vueData.isLoadingAddHocSinh = false
		}
	}
}
async function submitAddHocSinh() {
	if (!vueData.AddHocSinhSelected) {
		showModuleSnackbarHB('Vui lòng chọn học sinh', 'warning')
		return
	}
	vueData.isLoadingAdd = true
	try {
		const hs = vueData.AddHocSinhSelected
		let khoiNum = hs.KhoiID ? Number(hs.KhoiID) : 0
		if (!khoiNum && hs.TenLop) {
			const m = String(hs.TenLop).match(/^0?(\d+)/)
			if (m) khoiNum = Number(m[1])
		}
		if (!khoiNum && vueData.KhoiItem?.value) {
			khoiNum = Number(vueData.KhoiItem.value)
		}
		const payload = [{
			HocSinhID: hs.HocSinhID,
			HoTen: normalizeHocBongText(hs.HoTen || ((hs.Ho || '') + ' ' + (hs.Ten || ''))),
			TenLop: normalizeHocBongText(hs.TenLop),
			KhoiID: khoiNum,
			LopID: hs.LopID || 0,
			HocKy: vueData.Semester?.value || 1,
			NienKhoa: getNienKhoaCurrent(),
			MucHocBong: normalizeHocBongText(vueData.AddMucHocBong || '25% học phí học kì I'),
			TieuChi_VI: '',
			TieuChi_EN: '',
			NgayCap_VI: '',
			NgayCap_EN: '',
			SoQuyetDinh: '',
			VaoSo: null
		}]
		await ajaxCALLPromise('lms/HocBongCert_Ins_JSON', { JsonData: JSON.stringify(payload) })
		showModuleSnackbarHB('Đã thêm học sinh vào danh sách học bổng', 'success')
		vueData.IsShowDialogAdd = false
		await reloadHocBongList()
	} catch (error) {
		showModuleSnackbarHB('Thêm học sinh thất bại: ' + (error?.message || ''), 'error')
	} finally {
		vueData.isLoadingAdd = false
	}
}
async function submitDelHocSinh() {
	if (!vueData.DelHocSinhSelected || !vueData.DelHocSinhSelected.length) {
		showModuleSnackbarHB('Vui lòng chọn học sinh cần xóa', 'warning')
		return
	}
	vueData.isLoadingDel = true
	try {
		const ids = vueData.DelHocSinhSelected.map(x => ({ HocBongCertID: x.HocBongCertID }))
		await ajaxCALLPromise('lms/HocBongCert_Del_JSON', { JsonIDs: JSON.stringify(ids) })
		showModuleSnackbarHB(`Đã xóa ${ids.length} học sinh`, 'success')
		vueData.IsShowDialogDel = false
		vueData.DelHocSinhSelected = []
		await reloadHocBongList()
	} catch (error) {
		showModuleSnackbarHB('Xóa học sinh thất bại: ' + (error?.message || ''), 'error')
	} finally {
		vueData.isLoadingDel = false
	}
}
async function reloadHocBongList() {
	const khoiId = vueData.KhoiItem?.value ?? 0
	const hocKy = vueData.Semester?.value ?? 1
	const res = await ajaxCALLPromise('lms/HocBongCert_Get', {
		KhoiID: khoiId,
		HocKy: hocKy,
		NienKhoa: getNienKhoaCurrent()
	})
	let data = res
	if (Array.isArray(data) && data.length > 0 && Array.isArray(data[0])) {
		data = data[0]
	}
	vueData.DSHocBong = data || []
	renderDSHocBong()
}
// ==================== TAB 2: PHONG TRÀO THI ĐUA (MASTER - DETAIL) ====================
async function reloadPhongTraoMaster() {
	vueData.isLoadingMaster = true
	try {
		const khoiId = vueData.KhoiItem?.value ?? 0
		const hocKy = vueData.Semester?.value ?? 1
		const res = await ajaxCALLPromise('lms/GiayKhenPhongTrao_Get', {
			NienKhoa: getNienKhoaCurrent(),
			HocKy: hocKy,
			KhoiID: khoiId
		})
		let data = res
		if (Array.isArray(data) && data.length > 0 && Array.isArray(data[0])) {
			data = data[0]
		}
		// Chuẩn hóa danh sách dòng ngay sau khi tải để bảng, form sửa và luồng in cùng dùng một nguồn dữ liệu.
		const normalizedMasters = (data || []).map(item => {
			const normalized = normalizePhongTraoSchoolYear(item)
			const dongNoiDung = getMasterPhongTraoDongs(normalized)
			return {
				...normalized,
				DongNoiDung: dongNoiDung,
				...getLegacyPhongTraoLines(dongNoiDung)
			}
		})
		vueData.DSPhongTraoMaster = filterPhongTraoMasterByRole(normalizedMasters)
		if (vueData.selectedPhongTrao) {
			const found = vueData.DSPhongTraoMaster.find(x => x.PhongTraoID === vueData.selectedPhongTrao.PhongTraoID)
			if (found) {
				vueData.selectedPhongTrao = found
				ensureSelectedPrize(found)
				await reloadPhongTraoDetail(found.PhongTraoID)
			} else if (vueData.DSPhongTraoMaster.length > 0) {
				await selectPhongTrao(vueData.DSPhongTraoMaster[0])
			} else {
				vueData.selectedPhongTrao = null
				vueData.DSHocBongDetail = []
				vueData.DSHocBong = []
				vueData.DSHocSinh = []
				vueData.keyComp++
			}
		} else if (vueData.DSPhongTraoMaster.length > 0) {
			await selectPhongTrao(vueData.DSPhongTraoMaster[0])
		} else {
			vueData.selectedPhongTrao = null
			vueData.DSHocBongDetail = []
			vueData.DSHocBong = []
			vueData.DSHocSinh = []
			vueData.keyComp++
		}
		syncModuleRoleState()
	} catch (error) {
		console.error('reloadPhongTraoMaster error:', error)
		showModuleSnackbarHB('Lỗi tải danh mục phong trào: ' + (error?.message || ''), 'error')
	} finally {
		vueData.isLoadingMaster = false
	}
}
async function selectPhongTrao(item) {
	if (!item) return
	if (isGVCNHocBong() && Number(item.LoaiMau) !== 3) {
		showModuleSnackbarHB('GVCN chỉ được thao tác các phong trào Mẫu 3', 'warning')
		return
	}
	ensureSelectedPrize(item)
	vueData.selectedPhongTrao = item
	syncModuleRoleState()
	await reloadPhongTraoDetail(item.PhongTraoID)
}
async function reloadPhongTraoDetail(phongTraoId) {
	if (!phongTraoId) return
	vueData.isLoadingDetail = true
	try {
		// API chi tiết trả toàn bộ dòng của phong trào; GVCN phải nạp scope trước rồi mới lọc theo lớp chủ nhiệm.
		await ensureGVCNPhongTraoScope()
		const res = await ajaxCALLPromise('lms/GiayKhenPhongTraoChiTiet_Get', {
			PhongTraoID: phongTraoId
		})
		let data = res
		if (Array.isArray(data) && data.length > 0 && Array.isArray(data[0])) {
			data = data[0]
		}
		// API chỉ lọc theo PhongTraoID; tiếp tục lọc theo giải đang chọn để không trộn dữ liệu giữa các giải trong cùng group.
		// Chi tiết không trả NienKhoa riêng; selectedPhongTrao đã được lọc theo niên khóa nên áp dụng cùng nhãn năm học.
		const normalizedDetails = (data || []).map(item => {
			const normalized = normalizePhongTraoSchoolYear(item)
			const dongNoiDung = getMasterPhongTraoDongs({
				...vueData.selectedPhongTrao,
				...normalized,
				DongJson: normalized.DongJson || vueData.selectedPhongTrao?.DongJson
			})
			return { ...normalized, DongNoiDung: dongNoiDung, ...getLegacyPhongTraoLines(dongNoiDung) }
		})
		vueData.DSHocBongDetail = filterRecentlyDeletedPhongTraoDetails(
			filterPhongTraoDetailByRole(
				filterPhongTraoDetailsByPrize(normalizedDetails)
			)
		)
		vueData.DSHocBong = vueData.DSHocBongDetail
		renderDSPhongTraoDetail()
	} catch (error) {
		console.error('reloadPhongTraoDetail error:', error)
		showModuleSnackbarHB('Lỗi tải chi tiết khen thưởng: ' + (error?.message || ''), 'error')
	} finally {
		vueData.isLoadingDetail = false
	}
}
function renderDSPhongTraoDetail() {
	const lm = Number(vueData.selectedPhongTrao?.LoaiMau) || 1
	const isTapThe = lm === 4
	const isBlankMau3 = lm === 3
	if (lm === 1) {
		vueData.columnHeader = [
			{ title: 'STT', name: 'STT', width: 50, readOnly: true },
			{ title: 'Mã CT', name: 'ChiTietID', width: 70, readOnly: true },
			{ title: 'Lớp/Class', name: 'TenLop', width: 140 },
			{ title: 'Dòng 1: Danh hiệu (VI)', name: 'DanhHieu_VI', width: 420 },
			{ title: 'Dòng 2: Danh hiệu (EN)', name: 'DanhHieu_EN', width: 420 },
			{ title: 'Dòng 3: Năm học', name: 'NamHoc', width: 240, readOnly: true },
			{ title: 'Số QĐ & khen thưởng', name: 'SoQuyetDinhVaKhenThuong', width: 180 },
			{ title: 'Ngày ký (VI)', name: 'NgayCap_VI', width: 190 },
			{ title: 'Ngày ký (EN)', name: 'NgayCap_EN', width: 170 },
			{ title: 'Thao tác', name: 'ThaoTac', width: 85, type: 'html', readOnly: true }
		]
		vueData.DSHocSinh = (vueData.DSHocBongDetail || []).map((x, index) => {
			x.Title = x.DanhHieu_VI || `Khen thưởng #${x.ChiTietID}`
			return [
				index + 1,
				x.ChiTietID,
				normalizeHocBongText(x.TenLop),
				normalizeHocBongText(x.DanhHieu_VI),
				normalizeHocBongText(x.DanhHieu_EN),
				normalizeHocBongText(x.NamHoc),
				normalizeHocBongText(x.SoQuyetDinhVaKhenThuong),
				normalizeHocBongText(x.NgayCap_VI),
				normalizeHocBongText(x.NgayCap_EN),
				`<button class="hb-delete-detail" data-id="${x.ChiTietID}">Xóa</button>`
			]
		})
	} else if (lm === 2) {
		vueData.columnHeader = [
			{ title: 'STT', name: 'STT', width: 50, readOnly: true },
			{ title: 'Mã CT', name: 'ChiTietID', width: 70, readOnly: true },
			// Mẫu 2 đã in sẵn tên và lớp trên giấy khen: chỉ đọc để bảo toàn dữ liệu học sinh.
			{ title: 'Họ và tên học sinh', name: 'HoTen', width: 220, align: 'left', readOnly: true },
			{ title: 'Lớp', name: 'TenLop', width: 80, readOnly: true },
			{ title: 'Dòng 1: Danh hiệu (VI)', name: 'DanhHieu_VI', width: 350 },
			{ title: 'Dòng 2: Danh hiệu (EN)', name: 'DanhHieu_EN', width: 350 },
			{ title: 'Dòng 3: Năm học', name: 'NamHoc', width: 240, readOnly: true },
			{ title: 'Số QĐ & khen thưởng', name: 'SoQuyetDinhVaKhenThuong', width: 180 },
			{ title: 'Ngày ký (VI)', name: 'NgayCap_VI', width: 190 },
			{ title: 'Ngày ký (EN)', name: 'NgayCap_EN', width: 170 },
			{ title: 'Thao tác', name: 'ThaoTac', width: 85, type: 'html', readOnly: true }
		]
		vueData.DSHocSinh = (vueData.DSHocBongDetail || []).map((x, index) => {
			x.Title = `${x.HoTen || ''} - Lớp ${x.TenLop || ''} (${x.DanhHieu_VI || ''})`
			return [
				index + 1,
				x.ChiTietID,
				normalizeHocBongText(x.HoTen),
				normalizeHocBongText(x.TenLop),
				normalizeHocBongText(x.DanhHieu_VI),
				normalizeHocBongText(x.DanhHieu_EN),
				normalizeHocBongText(x.NamHoc),
				normalizeHocBongText(x.SoQuyetDinhVaKhenThuong),
				normalizeHocBongText(x.NgayCap_VI),
				normalizeHocBongText(x.NgayCap_EN),
				`<button class="hb-delete-detail" data-id="${x.ChiTietID}">Xóa</button>`
			]
		})
	} else {
		vueData.columnHeader = [
			{ title: 'STT', name: 'STT', width: 50, readOnly: true },
			{ title: 'Mã CT', name: 'ChiTietID', width: 70, readOnly: true },
			...(isTapThe ? [] : [{ title: isBlankMau3 ? 'Họ và tên học sinh' : 'Họ và tên HS (để trống)', name: 'HoTen', width: 220, align: 'left' }]),
			{ title: isTapThe ? 'Lớp/Class' : 'Lớp', name: 'TenLop', width: isTapThe ? 180 : 110 },
			...(isTapThe || isBlankMau3 ? [] : [{ title: 'Khối', name: 'KhoiID', width: 60, type: 'numeric' }]),
			{ title: 'Dòng 1: Nội dung chứng nhận (VI)', name: 'DanhHieu_VI', width: 380 },
			{ title: 'Dòng 2: Nội dung chứng nhận (EN)', name: 'DanhHieu_EN', width: 380 },
			{ title: 'Dòng 3: Năm học', name: 'NamHoc', width: 240, readOnly: true },
			{ title: 'Số QĐ & khen thưởng', name: 'SoQuyetDinhVaKhenThuong', width: 180 },
			{ title: 'Ngày ký (VI)', name: 'NgayCap_VI', width: 190 },
			{ title: 'Ngày ký (EN)', name: 'NgayCap_EN', width: 170 },
			{ title: 'Thao tác', name: 'ThaoTac', width: 85, type: 'html', readOnly: true }
		]
		vueData.DSHocSinh = (vueData.DSHocBongDetail || []).map((x, index) => {
			x.Title = isBlankMau3
				? (x.HoTen || x.TenLop ? `${x.HoTen || 'Chưa có tên'} - Lớp ${x.TenLop || 'chưa có lớp'}` : `Chưa chọn học sinh #${x.ChiTietID}`)
				: `${x.TenLop ? 'Lớp ' + x.TenLop : (x.KhoiID ? 'Khối ' + x.KhoiID : 'Tất cả')} - ${x.DanhHieu_VI || ''}`
			return [
				index + 1,
				x.ChiTietID,
				...(isTapThe ? [] : [normalizeHocBongText(x.HoTen)]),
				normalizeHocBongText(x.TenLop),
				...(isTapThe || isBlankMau3 ? [] : [x.KhoiID || '']),
				normalizeHocBongText(x.DanhHieu_VI),
				normalizeHocBongText(x.DanhHieu_EN),
				normalizeHocBongText(x.NamHoc),
				normalizeHocBongText(x.SoQuyetDinhVaKhenThuong),
				normalizeHocBongText(x.NgayCap_VI),
				normalizeHocBongText(x.NgayCap_EN),
				`<button class="hb-delete-detail" data-id="${x.ChiTietID}">Xóa</button>`
			]
		})
	}
	// Chế độ xem phải khóa cả ô chỉnh sửa và nút Xóa trong bảng,
	// tránh việc chỉ ẩn toolbar nhưng người dùng vẫn sửa được Jspreadsheet trực tiếp.
	if (!canManagePhongTraoDetail(vueData.selectedPhongTrao)) {
		vueData.columnHeader = vueData.columnHeader.map(column => ({ ...column, readOnly: true }))
		vueData.DSHocSinh = (vueData.DSHocSinh || []).map(row => {
			const viewRow = [...row]
			viewRow[viewRow.length - 1] = ''
			return viewRow
		})
	}
	vueData.canManageSelectedPhongTrao = canManagePhongTraoDetail(vueData.selectedPhongTrao)
	vueData.DSHocSinhChange = []
	vueData.keyComp++
}
// Master CRUD Handlers
function openAddPhongTraoMaster() {
	if (!canManagePhongTraoMaster()) {
		showModuleSnackbarHB('GVCN chỉ được thêm dữ liệu khen thưởng Mẫu 3', 'warning')
		return
	}
	vueData.IsEditingPhongTrao = false
	vueData.MasterForm_PhongTraoID = 0
	vueData.MasterForm_TenPhongTrao = ''
	vueData.MasterForm_LoaiMau = 1
	vueData.MasterForm_DongNoiDung = createDefaultPhongTraoDongs()
	const legacyLines = getLegacyPhongTraoLines(vueData.MasterForm_DongNoiDung)
	vueData.MasterForm_DanhHieu_VI = legacyLines.DanhHieu_VI
	vueData.MasterForm_DanhHieu_EN = legacyLines.DanhHieu_EN
	vueData.MasterForm_NamHoc = legacyLines.NamHoc
	vueData.MasterForm_NgayCap_VI = ''
	vueData.MasterForm_NgayCap_EN = ''
	vueData.MasterForm_SoQuyetDinh = ''
	vueData.MasterForm_KhoiItem = (vueData.DSKhoi || []).find(k => k.value === 0) || null
	vueData.MasterForm_GhiChu = ''
	vueData.MasterForm_CacGiai = DEFAULT_PHONG_TRAO_CAC_GIAI
	vueData.IsShowDialogAddPhongTraoMaster = true
}
function openEditPhongTraoMaster(item) {
	if (!item) return
	const raw = item?._master || item?.raw?._master || item?.raw || item
	if (!canManagePhongTraoMaster()) {
		showModuleSnackbarHB('GVCN chỉ được thêm dữ liệu khen thưởng Mẫu 3', 'warning')
		return
	}
	vueData.IsEditingPhongTrao = true
	vueData.MasterForm_PhongTraoID = raw.PhongTraoID
	vueData.MasterForm_TenPhongTrao = raw.TenPhongTrao || ''
	vueData.MasterForm_LoaiMau = Number(raw.LoaiMau) || 1
	// Form sửa hydrate toàn bộ danh sách dòng; không còn phụ thuộc ba field semantic của bảng master.
	vueData.MasterForm_DongNoiDung = getMasterPhongTraoDongs(raw)
	const legacyLines = getLegacyPhongTraoLines(vueData.MasterForm_DongNoiDung)
	vueData.MasterForm_DanhHieu_VI = legacyLines.DanhHieu_VI
	vueData.MasterForm_DanhHieu_EN = legacyLines.DanhHieu_EN
	// Giữ nguyên chuỗi rỗng từ DB để form sửa phản ánh đúng Dòng 3 đã được xóa; chỉ fallback khi API thật sự thiếu field.
	vueData.MasterForm_NamHoc = legacyLines.NamHoc
	// Các field master này chưa hiển thị trong form nhưng SP Save vẫn cập nhật; phải hydrate để không xóa dữ liệu cũ khi sửa field khác.
	vueData.MasterForm_NgayCap_VI = raw.NgayCap_VI || ''
	vueData.MasterForm_NgayCap_EN = raw.NgayCap_EN || ''
	vueData.MasterForm_SoQuyetDinh = raw.SoQuyetDinh || ''
	vueData.MasterForm_KhoiItem = (vueData.DSKhoi || []).find(k => Number(k.value) === Number(raw.KhoiID)) || (vueData.DSKhoi || []).find(k => k.value === 0) || null
	vueData.MasterForm_GhiChu = raw.GhiChu || ''
	vueData.MasterForm_CacGiai = raw.CacGiai_VI || ''
	vueData.IsShowDialogAddPhongTraoMaster = true
}
function addMasterDongNoiDung() {
	const rows = normalizeMasterPhongTraoDongs(vueData.MasterForm_DongNoiDung)
	rows.push(normalizePhongTraoDong({
		ThuTuDong: rows.length + 1,
		TenDong: `Dòng ${rows.length + 1}`,
		NgonNgu: 'ALL',
		NoiDung: '',
		KieuDuLieu: 'text',
		BatBuoc: 0,
		Enable: 1
	}, rows.length))
	vueData.MasterForm_DongNoiDung = rows
}
function removeMasterDongNoiDung(index) {
	const rows = normalizeMasterPhongTraoDongs(vueData.MasterForm_DongNoiDung)
	const target = rows[index]
	if (!target) return
	if (target.BatBuoc) {
		showModuleSnackbarHB(`${target.TenDong || `Dòng ${index + 1}`} là bắt buộc, không thể xóa`, 'warning')
		return
	}
	rows.splice(index, 1)
	vueData.MasterForm_DongNoiDung = rows
}
async function submitSavePhongTraoMaster() {
	if (!canManagePhongTraoMaster()) {
		showModuleSnackbarHB('GVCN không được thay đổi danh mục phong trào', 'warning')
		return
	}
	// Khóa request trước khi gọi API để không tạo hai lần cập nhật khi người dùng double-click hoặc event dialog bị lặp.
	if (vueData.isLoadingSavePhongTrao) return
	if (!vueData.MasterForm_TenPhongTrao?.trim()) {
		showModuleSnackbarHB('Vui lòng nhập tên phong trào', 'warning')
		return
	}
	const dongRows = normalizeMasterPhongTraoDongs(vueData.MasterForm_DongNoiDung)
	if (!dongRows.length) {
		showModuleSnackbarHB('Vui lòng tạo ít nhất một dòng nội dung giấy khen', 'warning')
		return
	}
	const missingRequiredLine = dongRows.find(row => row.BatBuoc && !String(row.NoiDung || '').trim())
	if (missingRequiredLine) {
		showModuleSnackbarHB(`Vui lòng nhập nội dung ${missingRequiredLine.TenDong || 'dòng bắt buộc'}`, 'warning')
		return
	}
	vueData.isLoadingSavePhongTrao = true
	try {
		const legacyLines = getLegacyPhongTraoLines(dongRows)
		// Gửi cả JSON dòng động và projection cũ để các màn hình/API in chưa nâng cấp vẫn hoạt động trong giai đoạn chuyển tiếp.
		const payload = {
			PhongTraoID: vueData.MasterForm_PhongTraoID || 0,
			TenPhongTrao: normalizeHocBongText(vueData.MasterForm_TenPhongTrao.trim()),
			LoaiMau: Number(vueData.MasterForm_LoaiMau) || 1,
			DanhHieu_VI: normalizeHocBongText(legacyLines.DanhHieu_VI.trim()),
			DanhHieu_EN: normalizeHocBongText(legacyLines.DanhHieu_EN.trim()),
			NamHoc: normalizeHocBongText(legacyLines.NamHoc.trim()),
			DongJson: JSON.stringify(dongRows),
			NgayCap_VI: normalizeHocBongText(vueData.MasterForm_NgayCap_VI?.trim() || ''),
			NgayCap_EN: normalizeHocBongText(vueData.MasterForm_NgayCap_EN?.trim() || ''),
			SoQuyetDinh: normalizeHocBongText(vueData.MasterForm_SoQuyetDinh?.trim() || ''),
			KhoiID: vueData.MasterForm_KhoiItem && typeof vueData.MasterForm_KhoiItem === 'object' ? (vueData.MasterForm_KhoiItem.value ?? 0) : Number(vueData.MasterForm_KhoiItem || 0),
			HocKy: vueData.Semester && typeof vueData.Semester === 'object' ? (vueData.Semester.value ?? 1) : Number(vueData.Semester || 1),
			NienKhoa: getNienKhoaCurrent(),
			// Danh sách giải được gửi cùng master; SP sẽ đồng bộ các dòng con theo tên tham số CacGiai.
			CacGiai: normalizeHocBongText(vueData.MasterForm_CacGiai?.trim() || ''),
			GhiChu: normalizeHocBongText(vueData.MasterForm_GhiChu?.trim() || ''),
			sys_UserID: vueData.user?.UserID || 'admin'
		}
		const res = await ajaxCALLPromise('lms/GiayKhenPhongTrao_Save', payload)
		let savedId = vueData.MasterForm_PhongTraoID
		if (!savedId) {
			let data = res
			if (Array.isArray(data) && data.length > 0 && Array.isArray(data[0])) data = data[0]
			if (Array.isArray(data) && data.length > 0) savedId = data[0].PhongTraoID
			else if (data && typeof data === 'object' && data.PhongTraoID) savedId = data.PhongTraoID
		}
		showModuleSnackbarHB('Đã lưu thông tin phong trào', 'success')
		vueData.IsShowDialogAddPhongTraoMaster = false
		await reloadPhongTraoMaster()
		if (savedId) {
			const target = (vueData.DSPhongTraoMaster || []).find(x => x.PhongTraoID === savedId)
			if (target) await selectPhongTrao(target)
		}
	} catch (error) {
		console.error('submitSavePhongTraoMaster error:', error)
		showModuleSnackbarHB('Lưu phong trào thất bại: ' + (error?.message || ''), 'error')
	} finally {
		vueData.isLoadingSavePhongTrao = false
	}
}
function openDelPhongTraoMaster(item) {
	if (!item) return
	const raw = item?._master || item?.raw?._master || item?.raw || item
	if (!canManagePhongTraoMaster()) {
		showModuleSnackbarHB('GVCN không được xóa danh mục phong trào', 'warning')
		return
	}
	vueData.itemPhongTraoToDelete = raw
	vueData.IsShowDialogDelPhongTraoMaster = true
}
async function submitDelPhongTraoMaster() {
	if (!canManagePhongTraoMaster()) {
		showModuleSnackbarHB('GVCN không được xóa danh mục phong trào', 'warning')
		return
	}
	if (!vueData.itemPhongTraoToDelete?.PhongTraoID) return
	vueData.isLoadingDelPhongTrao = true
	try {
		await ajaxCALLPromise('lms/GiayKhenPhongTrao_Del', {
			PhongTraoID: vueData.itemPhongTraoToDelete.PhongTraoID,
			sys_UserID: vueData.user?.UserID || 'admin'
		})
		showModuleSnackbarHB('Đã xóa phong trào thành công', 'success')
		vueData.IsShowDialogDelPhongTraoMaster = false
		if (vueData.selectedPhongTrao?.PhongTraoID === vueData.itemPhongTraoToDelete.PhongTraoID) {
			vueData.selectedPhongTrao = null
		}
		vueData.itemPhongTraoToDelete = null
		await reloadPhongTraoMaster()
	} catch (error) {
		console.error('submitDelPhongTraoMaster error:', error)
		showModuleSnackbarHB('Xóa phong trào thất bại: ' + (error?.message || ''), 'error')
	} finally {
		vueData.isLoadingDelPhongTrao = false
	}
}
// Detail CRUD Handlers
function filterDetailHocSinhOptions() {
	const khoiVal = vueData.DetailForm_KhoiItem?.value ?? 0
	const selectedClass = vueData.DetailForm_LopItem
	const lopId = selectedClass && typeof selectedClass === 'object' ? selectedClass.LopID : selectedClass
	let students = vueData.DSAllHocSinh || []
	if (lopId) students = students.filter(row => String(row.LopID) === String(lopId))
	if (khoiVal && Number(khoiVal) !== 0) {
		students = students.filter(row => {
			if (row.KhoiID) return Number(row.KhoiID) === Number(khoiVal)
			const match = String(row.TenLop || '').match(/^0?(\d+)/)
			return match ? Number(match[1]) === Number(khoiVal) : false
		})
	}
	vueData.DSFilteredHocSinh = students
	if (Array.isArray(vueData.DetailForm_HocSinhSelected)) {
		const allowedIds = new Set(students.map(row => String(row.HocSinhID)))
		vueData.DetailForm_HocSinhSelected = vueData.DetailForm_HocSinhSelected.filter(row => allowedIds.has(String(row.HocSinhID)))
	}
}
function onDetailKhoiChange(khoi) {
	const khoiVal = (khoi && typeof khoi === 'object') ? (khoi.value ?? 0) : Number(khoi || 0)
	if (!khoiVal || khoiVal === 0) {
		vueData.DSFilteredLop = vueData.DSAllLop || []
	} else {
		vueData.DSFilteredLop = (vueData.DSAllLop || []).filter(x => Number(x.KhoiID) === Number(khoiVal))
	}
	filterDetailHocSinhOptions()
}
function onDetailLopChange(lop) {
	vueData.DetailForm_LopItem = lop || null
	if (lop?.KhoiID && Number(vueData.DetailForm_KhoiItem?.value || 0) !== Number(lop.KhoiID)) {
		vueData.DetailForm_KhoiItem = (vueData.DSKhoi || []).find(item => Number(item.value) === Number(lop.KhoiID)) || vueData.DetailForm_KhoiItem
	}
	filterDetailHocSinhOptions()
}
async function openAddChiTietPT() {
	if (!vueData.selectedPhongTrao) {
		showModuleSnackbarHB('Vui lòng chọn phong trào trước khi thêm khen thưởng', 'warning')
		return
	}
	if (!canManagePhongTraoDetail(vueData.selectedPhongTrao)) {
		showModuleSnackbarHB('Bạn chỉ có quyền xem phong trào này', 'warning')
		return
	}
	const pt = vueData.selectedPhongTrao
	const prize = getSelectedPrizeContent(pt)
	vueData.DetailForm_DanhHieu_VI = prize.DanhHieu_VI || ''
	vueData.DetailForm_DanhHieu_EN = prize.DanhHieu_EN || ''
	vueData.DetailForm_VaoSo = (vueData.DSHocBongDetail?.length || 0) + 1
	vueData.DetailForm_NgayCap_VI = ''
	vueData.DetailForm_NgayCap_EN = ''
	vueData.DetailForm_SoQuyetDinhVaKhenThuong = `NO:${vueData.DetailForm_VaoSo}`
	vueData.DetailForm_HocSinhSelected = []
	vueData.DetailForm_LopSelected = []
	vueData.DetailForm_TenLop = ''
	vueData.DetailForm_LopItem = null
	vueData.DetailForm_KhoiItem = (vueData.DSKhoi || []).find(k => k.value === pt.KhoiID) || (vueData.DSKhoi || []).find(k => k.value === 0) || null
	// Mẫu 1, 3, 4 lấy lớp theo niên khóa; Mẫu 3 GVCN sẽ được giới hạn bằng GVCN trên tblLop.
	if ([1, 3, 4].includes(Number(pt.LoaiMau)) && (!vueData.DSAllLop || vueData.DSAllLop.length === 0)) {
		try {
			const res = await ajaxCALLPromise('lms/Lop_Get_ByNienKhoa', {
				NienKhoa: getNienKhoaCurrent(),
				SYS_USERID: vueData.user?.UserID || 'admin'
			})
			let data = res
			if (Array.isArray(data) && data.length > 0 && Array.isArray(data[0])) data = data[0]
			const list = Array.isArray(data) ? data : []
			vueData.DSAllLop = list.map(normalizePhongTraoClassRow)
		} catch (e) {
			console.error('Error loading DSAllLop:', e)
		}
	}
	if (Number(pt.LoaiMau) === 3 && isGVCNHocBong()) {
		try {
			await ensureGVCNPhongTraoScope()
		} catch (e) {
			console.error('Error loading GVCN Phong Trao scope:', e)
			showModuleSnackbarHB('Không tải được danh sách lớp chủ nhiệm và học sinh', 'error')
			return
		}
	}
	onDetailKhoiChange(vueData.DetailForm_KhoiItem)
	vueData.IsShowDialogAddChiTietPT = true
	if ([2, 3].includes(Number(pt.LoaiMau)) && (!vueData.DSAllHocSinh || vueData.DSAllHocSinh.length === 0)) {
		try {
			const res = await ajaxCALLPromise('lms/HocSinh_Get', { NienKhoa: getNienKhoaCurrent() })
			const list = unwrapHocBongApiRows(res)
			vueData.DSAllHocSinh = list.map(x => {
				const label = `${x.HoTen || ((x.Ho || '') + ' ' + (x.Ten || ''))} - ${x.TenLop || ''} (MSHS ${x.HocSinhID || ''})`
				return { ...x, Title: label, title: label }
			})
			onDetailKhoiChange(vueData.DetailForm_KhoiItem)
		} catch (e) {
			console.error(e)
		}
	}
}
async function submitAddChiTietPT() {
	if (!vueData.selectedPhongTrao) return
	if (!canManagePhongTraoDetail(vueData.selectedPhongTrao)) {
		showModuleSnackbarHB('Bạn chỉ có quyền xem phong trào này', 'warning')
		return
	}
	const pt = vueData.selectedPhongTrao
	const prize = getSelectedPrizeContent(pt)
	const lm = Number(pt.LoaiMau) || 1
	let payload = []
	const startVaoSo = (vueData.DSHocBongDetail?.length || 0) + 1
	if ([2, 3].includes(lm)) {
		const hsList = Array.isArray(vueData.DetailForm_HocSinhSelected)
			? vueData.DetailForm_HocSinhSelected
			: (vueData.DetailForm_HocSinhSelected ? [vueData.DetailForm_HocSinhSelected] : [])
		if (hsList.length === 0) {
			showModuleSnackbarHB('Vui lòng chọn học sinh', 'warning')
			return
		}
		// Mẫu 3 chỉ cho GVCN chọn các em thuộc lớp có GVCN trùng tài khoản đang đăng nhập.
		// Kiểm tra lại trước khi gửi payload để không thể vượt phạm vi bằng dữ liệu chỉnh từ DevTools.
		if (lm === 3 && isGVCNHocBong()) {
			const allowedIds = new Set((vueData.DSAllHocSinh || []).map(row => String(row.HocSinhID)))
			if (hsList.some(hs => !allowedIds.has(String(hs?.HocSinhID)))) {
				showModuleSnackbarHB('Học sinh được chọn không thuộc lớp chủ nhiệm của bạn', 'warning')
				return
			}
		}
		hsList.forEach((hs, idx) => {
			let khoiNum = hs.KhoiID ? Number(hs.KhoiID) : 0
			if (!khoiNum && hs.TenLop) {
				const m = String(hs.TenLop).match(/^0?(\d+)/)
				if (m) khoiNum = Number(m[1])
			}
			const vaoSo = startVaoSo + idx
			const sqd = vueData.DetailForm_SoQuyetDinhVaKhenThuong || `NO:${vaoSo}`
			payload.push({
				PhongTraoID: pt.PhongTraoID,
				HocSinhID: hs.HocSinhID || 0,
				HoTen: normalizeHocBongText(hs.HoTen || ((hs.Ho || '') + ' ' + (hs.Ten || ''))),
				TenLop: normalizeHocBongText(hs.TenLop),
				LopID: hs.LopID || 0,
				KhoiID: khoiNum || pt.KhoiID || 0,
				VaoSo: vaoSo,
				DanhHieu_VI: normalizeHocBongText(prize.DanhHieu_VI),
				DanhHieu_EN: normalizeHocBongText(prize.DanhHieu_EN),
				SoQuyetDinhVaKhenThuong: normalizeHocBongText(sqd)
			})
		})
	} else if (lm === 1) {
		// Mẫu 1 tạo đúng một dòng theo lớp được chọn từ danh sách API của niên khóa hiện tại.
		const selectedClass = vueData.DetailForm_LopItem || (vueData.DSAllLop || []).find(item => String(item.value ?? item.TenLop ?? '') === String(vueData.DetailForm_TenLop || ''))
		const tenLop = normalizeHocBongText((typeof selectedClass === 'object' ? (selectedClass.TenLop || selectedClass.value || '') : selectedClass || '').trim())
		if (!tenLop) {
			showModuleSnackbarHB('Vui lòng chọn lớp trong niên khóa hiện tại', 'warning')
			return
		}
		const vaoSo = startVaoSo
		const sqd = vueData.DetailForm_SoQuyetDinhVaKhenThuong || `NO:${vaoSo}`
		payload.push({
			PhongTraoID: pt.PhongTraoID,
			HocSinhID: 0,
			HoTen: '',
			TenLop: tenLop,
			LopID: selectedClass?.LopID || 0,
			KhoiID: selectedClass?.KhoiID || 0,
			VaoSo: vaoSo,
			DanhHieu_VI: normalizeHocBongText(prize.DanhHieu_VI),
			DanhHieu_EN: normalizeHocBongText(prize.DanhHieu_EN),
			SoQuyetDinhVaKhenThuong: normalizeHocBongText(sqd)
		})
	} else if (lm === 4) {
		// Mẫu tập thể chỉ tạo một dòng đại diện cho lớp đã chọn trong niên khóa hiện tại.
		const tenLop = normalizeHocBongText(vueData.DetailForm_TenLop?.trim() || '')
		if (!tenLop) {
			showModuleSnackbarHB('Vui lòng chọn lớp trong niên khóa hiện tại', 'warning')
			return
		}
		// Lưu cả khóa lớp và khối từ danh sách niên khóa để dữ liệu tập thể không chỉ còn tên lớp dạng chuỗi.
		const selectedClass = (vueData.DSAllLop || []).find(item => String(item.value ?? item.TenLop ?? '') === String(tenLop))
		const vaoSo = startVaoSo
		const sqd = vueData.DetailForm_SoQuyetDinhVaKhenThuong || `NO:${vaoSo}`
		payload.push({
			PhongTraoID: pt.PhongTraoID,
			HocSinhID: 0,
			HoTen: '',
			TenLop: tenLop,
			LopID: selectedClass?.LopID || 0,
			KhoiID: selectedClass?.KhoiID || pt.KhoiID || 0,
			VaoSo: vaoSo,
			DanhHieu_VI: normalizeHocBongText(prize.DanhHieu_VI),
			DanhHieu_EN: normalizeHocBongText(prize.DanhHieu_EN),
			SoQuyetDinhVaKhenThuong: normalizeHocBongText(sqd)
		})
	} else {
		// Loại mẫu chưa xác định vẫn dùng một phôi trắng an toàn, không tự gắn học sinh/lớp.
		const vaoSo = startVaoSo
		const sqd = vueData.DetailForm_SoQuyetDinhVaKhenThuong || `NO:${vaoSo}`
		payload.push({
			PhongTraoID: pt.PhongTraoID,
			HocSinhID: 0,
			HoTen: '',
			TenLop: '',
			LopID: 0,
			KhoiID: 0,
			VaoSo: vaoSo,
			DanhHieu_VI: normalizeHocBongText(prize.DanhHieu_VI),
			DanhHieu_EN: normalizeHocBongText(prize.DanhHieu_EN),
			SoQuyetDinhVaKhenThuong: normalizeHocBongText(sqd)
		})
	}
	payload.forEach(row => {
		row.NgayCap_VI = normalizeHocBongText(vueData.DetailForm_NgayCap_VI?.trim() || '')
		row.NgayCap_EN = normalizeHocBongText(vueData.DetailForm_NgayCap_EN?.trim() || '')
	})
	vueData.isLoadingAddChiTietPT = true
	try {
		await ajaxCALLPromise('lms/GiayKhenPhongTraoChiTiet_Ins_JSON', {
			JsonData: JSON.stringify(payload),
			sys_UserID: vueData.user?.UserID || 'admin'
		})
		showModuleSnackbarHB('Đã thêm khen thưởng thành công', 'success')
		vueData.IsShowDialogAddChiTietPT = false
		await reloadPhongTraoDetail(pt.PhongTraoID)
		await reloadPhongTraoMaster()
	} catch (error) {
		console.error('submitAddChiTietPT error:', error)
		showModuleSnackbarHB('Thêm khen thưởng thất bại: ' + (error?.message || ''), 'error')
	} finally {
		vueData.isLoadingAddChiTietPT = false
	}
}
async function submitDelChiTietPT() {
	if (!vueData.DelChiTietPTSelected || !vueData.DelChiTietPTSelected.length) {
		showModuleSnackbarHB('Vui lòng chọn khen thưởng cần xóa', 'warning')
		return
	}
	if (!canManagePhongTraoDetail(vueData.selectedPhongTrao)) {
		showModuleSnackbarHB('Bạn chỉ có quyền xem phong trào này', 'warning')
		return
	}
	vueData.isLoadingDelChiTietPT = true
	try {
		// SP dùng OPENJSON(... WITH (ChiTietID INT '$')), vì vậy payload phải là mảng số [35], không phải [{ ChiTietID: 35 }].
		const ids = [...new Set(vueData.DelChiTietPTSelected.map(x => Number(x.ChiTietID)).filter(Number.isInteger))]
		if (!ids.length) throw new Error('Không xác định được mã khen thưởng cần xóa')
		const response = await ajaxCALLPromise('lms/GiayKhenPhongTraoChiTiet_Del_JSON', {
			JsonIDs: JSON.stringify(ids),
			sys_UserID: vueData.user?.UserID || 'admin'
		})
		const deletedCount = getDeletedCount(response)
		// Không hiển thị thành công nếu SP trả Deleted = 0 hoặc xóa thiếu dòng; tránh tình trạng toast thành công nhưng bảng vẫn còn dữ liệu.
		if (deletedCount !== ids.length) {
			if (vueData.selectedPhongTrao) await reloadPhongTraoDetail(vueData.selectedPhongTrao.PhongTraoID)
			throw new Error(`Server xác nhận xóa ${deletedCount ?? 0}/${ids.length} khen thưởng`)
		}
		// Cập nhật tức thời theo đúng ID server đã xác nhận; tránh GET kế tiếp trả dữ liệu cũ làm dòng vừa xóa xuất hiện lại.
		vueData.deletedPhongTraoDetailIds = [...new Set([...(vueData.deletedPhongTraoDetailIds || []), ...ids])]
		vueData.DSHocBongDetail = filterRecentlyDeletedPhongTraoDetails(vueData.DSHocBongDetail)
		vueData.DSHocBong = vueData.DSHocBongDetail
		renderDSPhongTraoDetail()
		showModuleSnackbarHB(`Đã xóa ${ids.length} khen thưởng`, 'success')
		vueData.IsShowDialogDelChiTietPT = false
		vueData.DelChiTietPTSelected = []
		if (vueData.selectedPhongTrao) {
			await reloadPhongTraoMaster()
		}
	} catch (error) {
		console.error('submitDelChiTietPT error:', error)
		showModuleSnackbarHB('Xóa khen thưởng thất bại: ' + (error?.message || ''), 'error')
	} finally {
		vueData.isLoadingDelChiTietPT = false
	}
}
async function openEditChiTietPT(item) {
	if (!vueData.DSHocBongDetail || vueData.DSHocBongDetail.length === 0) {
		showModuleSnackbarHB('Chưa có khen thưởng nào để sửa', 'warning')
		return
	}
	if (!canManagePhongTraoDetail(vueData.selectedPhongTrao)) {
		showModuleSnackbarHB('Bạn chỉ có quyền xem phong trào này', 'warning')
		return
	}
	const loaiMau = Number(vueData.selectedPhongTrao?.LoaiMau)
	// Mẫu 1, 3, 4 sửa lớp từ danh sách API của niên khóa hiện tại.
	if ([1, 3, 4].includes(loaiMau) && (!vueData.DSAllLop || vueData.DSAllLop.length === 0)) {
		try {
			const res = await ajaxCALLPromise('lms/Lop_Get_ByNienKhoa', {
				NienKhoa: getNienKhoaCurrent(),
				SYS_USERID: vueData.user?.UserID || 'admin'
			})
			let data = res
			if (Array.isArray(data) && data.length > 0 && Array.isArray(data[0])) data = data[0]
			const list = Array.isArray(data) ? data : []
			vueData.DSAllLop = list.map(normalizePhongTraoClassRow)
		} catch (e) {
			console.error('Error loading DSAllLop:', e)
		}
	}
	// GVCN dùng đúng quan hệ tblLop.GVCN -> tblHocSinhLop để mở danh sách học sinh được phép sửa.
	if (loaiMau === 3 && isGVCNHocBong()) {
		try {
			await ensureGVCNPhongTraoScope()
		} catch (e) {
			console.error('Error loading GVCN Phong Trao scope in edit:', e)
			showModuleSnackbarHB('Không tải được danh sách lớp chủ nhiệm và học sinh', 'error')
			return
		}
	}
	if ([2, 3].includes(loaiMau) && (!vueData.DSAllHocSinh || vueData.DSAllHocSinh.length === 0)) {
		try {
			const res = await ajaxCALLPromise('lms/HocSinh_Get', { NienKhoa: getNienKhoaCurrent() })
			const list = unwrapHocBongApiRows(res)
			vueData.DSAllHocSinh = list.map(x => ({
				...x,
				Title: `${x.HoTen || ((x.Ho || '') + ' ' + (x.Ten || ''))} - Lớp ${x.TenLop || ''} (${x.HocSinhID || ''})`,
				value: x.HocSinhID
			}))
			onEditDetailKhoiChange(vueData.EditDetail_KhoiItem)
		} catch (e) {
			console.error('Error loading DSAllHocSinh in edit:', e)
		}
	}
	const target = item || vueData.DSHocBongDetail[0]
	vueData.EditDetail_SelectedRecord = target
	onSelectEditDetailRecord(target)
	vueData.IsShowDialogEditChiTietPT = true
}
function onSelectEditDetailRecord(item) {
	if (!item) return
	vueData.EditDetail_ChiTietID = item.ChiTietID
	vueData.EditDetail_HoTen = item.HoTen || ''
	vueData.EditDetail_TenLop = item.TenLop || ''
	vueData.EditDetail_KhoiID = item.KhoiID ?? 0
	vueData.EditDetail_DanhHieu_VI = item.DanhHieu_VI || ''
	vueData.EditDetail_DanhHieu_EN = item.DanhHieu_EN || ''
	vueData.EditDetail_VaoSo = item.VaoSo ?? ''
	vueData.EditDetail_SoQuyetDinhVaKhenThuong = item.SoQuyetDinhVaKhenThuong || ''
	vueData.EditDetail_NgayCap_VI = item.NgayCap_VI || ''
	vueData.EditDetail_NgayCap_EN = item.NgayCap_EN || ''
	// Set EditDetail_KhoiItem
	vueData.EditDetail_KhoiItem = (vueData.DSKhoi || []).find(k => Number(k.value) === Number(item.KhoiID)) || (vueData.DSKhoi || []).find(k => k.value === 0) || null
	// Filter classes / students for this khối
	onEditDetailKhoiChange(vueData.EditDetail_KhoiItem)
	// Set EditDetail_LopItem
	if (item.TenLop) {
		vueData.EditDetail_LopItem = (vueData.DSAllLop || []).find(l => (l.TenLop || l.value) === item.TenLop) || { TenLop: item.TenLop, title: item.TenLop, value: item.TenLop }
	} else {
		vueData.EditDetail_LopItem = null
	}
	onEditDetailLopChange(vueData.EditDetail_LopItem)
	// Set EditDetail_HocSinhItem
	if (item.HocSinhID && vueData.DSAllHocSinh) {
		vueData.EditDetail_HocSinhItem = (vueData.DSAllHocSinh || []).find(h => String(h.HocSinhID) === String(item.HocSinhID)) || null
	} else {
		vueData.EditDetail_HocSinhItem = null
	}
}
function onEditDetailKhoiChange(khoi) {
	const khoiVal = (khoi && typeof khoi === 'object') ? (khoi.value ?? 0) : Number(khoi || 0)
	if (!khoiVal || khoiVal === 0) {
		vueData.DSEditFilteredLop = vueData.DSAllLop || []
	} else {
		vueData.DSEditFilteredLop = (vueData.DSAllLop || []).filter(x => Number(x.KhoiID) === Number(khoiVal))
	}
	let students = vueData.DSAllHocSinh || []
	const selectedClass = vueData.EditDetail_LopItem
	const lopId = selectedClass && typeof selectedClass === 'object' ? selectedClass.LopID : selectedClass
	if (lopId) students = students.filter(row => String(row.LopID) === String(lopId))
	if (khoiVal && Number(khoiVal) !== 0) {
		students = students.filter(row => {
			if (row.KhoiID) return Number(row.KhoiID) === Number(khoiVal)
			const match = String(row.TenLop || '').match(/^0?(\d+)/)
			return match ? Number(match[1]) === Number(khoiVal) : false
		})
	}
	vueData.DSEditFilteredHocSinh = students
}
function onEditDetailLopChange(lop) {
	vueData.EditDetail_LopItem = lop || null
	if (lop?.KhoiID && Number(vueData.EditDetail_KhoiItem?.value || 0) !== Number(lop.KhoiID)) {
		vueData.EditDetail_KhoiItem = (vueData.DSKhoi || []).find(item => Number(item.value) === Number(lop.KhoiID)) || vueData.EditDetail_KhoiItem
	}
	onEditDetailKhoiChange(vueData.EditDetail_KhoiItem)
}
function onEditDetailHocSinhChange(hs) {
	if (hs && typeof hs === 'object') {
		vueData.EditDetail_HoTen = hs.HoTen || ((hs.Ho || '') + ' ' + (hs.Ten || ''))
		vueData.EditDetail_TenLop = hs.TenLop || ''
		if (hs.KhoiID) {
			vueData.EditDetail_KhoiID = hs.KhoiID
			vueData.EditDetail_KhoiItem = (vueData.DSKhoi || []).find(k => Number(k.value) === Number(hs.KhoiID)) || vueData.EditDetail_KhoiItem
		}
		if (hs.LopID) {
			vueData.EditDetail_LopItem = (vueData.DSAllLop || []).find(row => String(row.LopID) === String(hs.LopID)) || vueData.EditDetail_LopItem
		}
		onEditDetailLopChange(vueData.EditDetail_LopItem)
	}
}
async function submitSaveEditChiTietPT() {
	if (!vueData.EditDetail_ChiTietID) {
		showModuleSnackbarHB('Vui lòng chọn mục khen thưởng cần sửa', 'warning')
		return
	}
	if (!canManagePhongTraoDetail(vueData.selectedPhongTrao)) {
		showModuleSnackbarHB('Bạn chỉ có quyền xem phong trào này', 'warning')
		return
	}
	vueData.isLoadingSaveEditDetail = true
	try {
		const isMau1 = Number(vueData.selectedPhongTrao?.LoaiMau) === 1
		const isMau2 = Number(vueData.selectedPhongTrao?.LoaiMau) === 2
		const isMau3 = Number(vueData.selectedPhongTrao?.LoaiMau) === 3
		const isMau4 = Number(vueData.selectedPhongTrao?.LoaiMau) === 4
		const isStudentTemplate = isMau2 || isMau3
		const selectedStudent = vueData.EditDetail_HocSinhItem
		const selectedClass = (isMau1 || isMau4 || isStudentTemplate) ? vueData.EditDetail_LopItem : null
		const khoiNum = isMau1
			? 0
			: isMau4
				? (selectedClass?.KhoiID || vueData.EditDetail_KhoiItem?.value || Number(vueData.EditDetail_KhoiID) || 0)
			: isStudentTemplate
				? (selectedStudent?.KhoiID || selectedClass?.KhoiID || vueData.EditDetail_KhoiItem?.value || Number(vueData.EditDetail_KhoiID) || 0)
				: (vueData.EditDetail_KhoiItem?.value ?? Number(vueData.EditDetail_KhoiID) ?? 0)
		const lopName = isMau1
				? (selectedClass?.TenLop || selectedClass?.value || vueData.EditDetail_TenLop || '')
			: isStudentTemplate
				? (selectedClass?.TenLop || selectedClass?.value || selectedStudent?.TenLop || vueData.EditDetail_TenLop || '')
				: (vueData.EditDetail_LopItem
				? (typeof vueData.EditDetail_LopItem === 'object' ? (vueData.EditDetail_LopItem.TenLop || vueData.EditDetail_LopItem.value || '') : String(vueData.EditDetail_LopItem))
				: (vueData.EditDetail_TenLop || ''))
		if (isMau1 && !lopName.trim()) {
			showModuleSnackbarHB('Vui lòng nhập lớp', 'warning')
			return
		}
		if (Number(vueData.selectedPhongTrao?.LoaiMau) === 4 && !lopName.trim()) {
			showModuleSnackbarHB('Vui lòng chọn lớp trong niên khóa hiện tại', 'warning')
			return
		}
		const hoTen = isStudentTemplate
			? (selectedStudent?.HoTen || ((selectedStudent?.Ho || '') + ' ' + (selectedStudent?.Ten || '')) || vueData.EditDetail_HoTen || '')
			: isMau1 ? '' : (vueData.EditDetail_HoTen || '')
		if (isStudentTemplate && !hoTen.trim()) {
			showModuleSnackbarHB('Vui lòng chọn học sinh', 'warning')
			return
		}
		if (isMau3 && isGVCNHocBong()) {
			const allowedIds = new Set((vueData.DSAllHocSinh || []).map(row => String(row.HocSinhID)))
			if (!selectedStudent?.HocSinhID || !allowedIds.has(String(selectedStudent.HocSinhID))) {
				showModuleSnackbarHB('Học sinh được chọn không thuộc lớp chủ nhiệm của bạn', 'warning')
				return
			}
		}
		const payload = [{
			ChiTietID: vueData.EditDetail_ChiTietID,
			HocSinhID: isStudentTemplate ? (selectedStudent?.HocSinhID || 0) : 0,
			HoTen: normalizeHocBongText(hoTen.trim()),
			TenLop: normalizeHocBongText(lopName.trim()),
			KhoiID: khoiNum,
			VaoSo: Number(vueData.EditDetail_VaoSo) || null,
			DanhHieu_VI: normalizeHocBongText(vueData.EditDetail_DanhHieu_VI?.trim() || ''),
			DanhHieu_EN: normalizeHocBongText(vueData.EditDetail_DanhHieu_EN?.trim() || ''),
			SoQuyetDinhVaKhenThuong: normalizeHocBongText(vueData.EditDetail_SoQuyetDinhVaKhenThuong?.trim() || ''),
			NgayCap_VI: normalizeHocBongText(vueData.EditDetail_NgayCap_VI?.trim() || ''),
			NgayCap_EN: normalizeHocBongText(vueData.EditDetail_NgayCap_EN?.trim() || '')
		}]
		await ajaxCALLPromise('lms/GiayKhenPhongTraoChiTiet_Upd_JSON', {
			JsonData: JSON.stringify(payload),
			sys_UserID: vueData.user?.UserID || 'admin'
		})
		const orig = (vueData.DSHocBongDetail || []).find(x => x.ChiTietID === vueData.EditDetail_ChiTietID)
		if (orig) Object.assign(orig, payload[0])
		renderDSPhongTraoDetail()
		vueData.IsShowDialogEditChiTietPT = false
		showModuleSnackbarHB('Đã cập nhật khen thưởng thành công', 'success')
	} catch (error) {
		console.error('submitSaveEditChiTietPT error:', error)
		showModuleSnackbarHB('Cập nhật thất bại: ' + (error?.message || ''), 'error')
	} finally {
		vueData.isLoadingSaveEditDetail = false
	}
}
function onSavePTDetail() {
	if (!canManagePhongTraoDetail(vueData.selectedPhongTrao)) {
		showModuleSnackbarHB('Bạn chỉ có quyền xem phong trào này', 'warning')
		return
	}
	if (!vueData.DSHocSinhChange || !vueData.DSHocSinhChange.length) {
		showModuleSnackbarHB('Không có thay đổi nào để lưu', 'warning')
		return
	}
	vueData.IsShowDialogConfirm = true
}
async function confirmSavePTDetail() {
	if (!canManagePhongTraoDetail(vueData.selectedPhongTrao)) {
		showModuleSnackbarHB('Bạn chỉ có quyền xem phong trào này', 'warning')
		return
	}
	vueData.isLoadingSave = true
	try {
		const instance = Array.isArray(vueData.instance) ? vueData.instance[0] : vueData.instance
		const rows = instance.getData()
		const keys = vueData.columnHeader.map(c => c.name)
		const objs = rows.map(r => {
			const o = {}
			keys.forEach((k, i) => { o[k] = r[i] })
			return o
		})
		const changedIds = new Set((vueData.DSHocSinhChange || []).map(String))
		const payload = objs
			.filter(o => changedIds.has(String(o.ChiTietID)))
			.map(o => {
				const orig = (vueData.DSHocBongDetail || []).find(x => String(x.ChiTietID) === String(o.ChiTietID))
				return {
					ChiTietID: orig?.ChiTietID,
					HoTen: o.HoTen !== undefined ? normalizeHocBongText(o.HoTen) : orig?.HoTen,
					TenLop: o.TenLop !== undefined ? normalizeHocBongText(o.TenLop) : orig?.TenLop,
					KhoiID: o.KhoiID !== undefined ? (Number(String(o.KhoiID).replace(/\D/g, '')) || 0) : orig?.KhoiID,
					VaoSo: o.VaoSo !== undefined ? (o.VaoSo ? Number(o.VaoSo) : null) : orig?.VaoSo,
					DanhHieu_VI: normalizeHocBongText(o.DanhHieu_VI),
					DanhHieu_EN: normalizeHocBongText(o.DanhHieu_EN),
					SoQuyetDinhVaKhenThuong: o.SoQuyetDinhVaKhenThuong !== undefined
						? normalizeHocBongText(o.SoQuyetDinhVaKhenThuong)
						: orig?.SoQuyetDinhVaKhenThuong,
					NgayCap_VI: orig?.NgayCap_VI || '',
					NgayCap_EN: orig?.NgayCap_EN || ''
				}
			})
		await ajaxCALLPromise('lms/GiayKhenPhongTraoChiTiet_Upd_JSON', {
			JsonData: JSON.stringify(payload),
			sys_UserID: vueData.user?.UserID || 'admin'
		})
		payload.forEach(p => {
			const orig = (vueData.DSHocBongDetail || []).find(x => x.ChiTietID === p.ChiTietID)
			if (orig) Object.assign(orig, p)
		})
		renderDSPhongTraoDetail()
		vueData.IsShowDialogConfirm = false
		showModuleSnackbarHB('Đã lưu thành công', 'success')
	} catch (error) {
		console.error('confirmSavePTDetail error:', error)
		showModuleSnackbarHB('Lưu thất bại: ' + (error?.message || ''), 'error')
	} finally {
		vueData.isLoadingSave = false
	}
}
function onExportExcelPTDetail() {
	if (!vueData.DSHocSinh || !vueData.DSHocSinh.length) return
	const headerRow = vueData.columnHeader.map(c => c.title)
	const aoa = [headerRow, ...vueData.DSHocSinh]
	const worksheet = XLSX.utils.aoa_to_sheet(aoa)
	const workbook = XLSX.utils.book_new()
	const sheetName = (vueData.selectedPhongTrao?.TenPhongTrao || 'PhongTrao').substring(0, 31).replace(/[\\\/\?\*\[\]]/g, '')
	XLSX.utils.book_append_sheet(workbook, worksheet, sheetName)
	XLSX.writeFile(workbook, `KhenThuong_${sheetName}_${getNienKhoaCurrent()}.xlsx`)
}
// In giấy chứng nhận / giấy khen cho Tab Phong trào & Thi đua
// Hỗ trợ cả 3 Mẫu Khen thưởng Phong trào & Thi đua (multi-pdf-movement) và Mẫu Giấy khen Tập thể (multi-pdf-collective)
async function exportGiayKhenPTDetail() {
	const details = Array.isArray(vueData.DSHocBongDetail) ? vueData.DSHocBongDetail : []
	if (!details.length) {
		showModuleSnackbarHB('Không có dữ liệu khen thưởng để in', 'warning')
		return
	}
	const pt = vueData.selectedPhongTrao
	if (!canManagePhongTraoDetail(pt)) {
		showModuleSnackbarHB('Bạn chỉ có quyền xem phong trào này', 'warning')
		return
	}
	const lm = Number(pt?.LoaiMau) || 1
	vueData.isLoadingPrint = true
	// Chuẩn bị danh sách certs đúng theo quy chuẩn tài liệu tích hợp API
	const certs = details.map(x => {
		// Generator hiện tại vẫn nhận ba placeholder noiDung1/2/3; lấy chúng từ danh sách dòng động qua mã tương thích.
		const dynamicLines = getMasterPhongTraoDongs({ ...pt, ...x, DongJson: x.DongJson || pt?.DongJson, DongNoiDung: x.DongNoiDung || pt?.DongNoiDung })
		const legacyLines = getLegacyPhongTraoLines(dynamicLines)
		// Dòng nội dung 1: Tên giải / thành tích tiếng Việt (In đậm + In nghiêng)
		const noiDung1 = normalizeHocBongText(x.DanhHieu_VI || legacyLines.DanhHieu_VI || '')
		// Dòng nội dung 2: Dòng tiếng Anh (In nghiêng)
		const noiDung2 = normalizeHocBongText(x.DanhHieu_EN || legacyLines.DanhHieu_EN || '')
		// Dòng nội dung 3: Dòng năm học (In nghiêng)
		const noiDung3 = normalizeHocBongText(x.NamHoc ?? legacyLines.NamHoc ?? getPhongTraoSchoolYearLabel())
		// Ngày cấp tiếng Việt & tiếng Anh
		const ngayThangNam_Vi = normalizeHocBongText(x.NgayCap_VI || '')
		const ngayThangNam_En = normalizeHocBongText(x.NgayCap_EN || '')
		// Số quyết định & Tên hiệu trưởng
		const soQuyetDinh = normalizeHocBongText(x.SoQuyetDinhVaKhenThuong || (x.VaoSo ? `NO:${x.VaoSo}` : ''))
		const tenHieuTruong = 'Hoàng Thị Diễm Trang'
		// Phân nhánh format theo từng loại mẫu theo đúng tài liệu API xuất giấy khen:
		// Mẫu 1: Khen tập thể cuộc thi (lop: 'LỚP/ CLASS' hoặc tên lớp)
		// Mẫu 2: Khen cá nhân học sinh (hoTen: Tên HS in hoa 28pt, lop: Tên lớp)
		// Mẫu 3 vẫn là mẫu phôi, nhưng GVCN chọn học sinh trong danh sách lớp chủ nhiệm trước khi in.
		// Nếu còn bản ghi phôi cũ chưa có học sinh thì giữ fallback rỗng để vẫn in được phôi đó.
		// Mẫu 4: Giấy khen tập thể (multi-pdf-collective)
		if (lm === 2) {
			return {
				mau: 2,
				khenTang_Vi: 'Khen tặng học sinh',
				khenTang_En: 'This certificate is proudly presented to',
				hoTen: String(x.HoTen || '').toUpperCase().trim(),
				lop: x.TenLop ? String(x.TenLop).trim() : '',
				noiDung1: noiDung1,
				noiDung2: noiDung2,
				noiDung3: noiDung3,
				ngayThangNam_Vi: ngayThangNam_Vi,
				ngayThangNam_En: ngayThangNam_En,
				soQuyetDinh: soQuyetDinh,
				tenHieuTruong: tenHieuTruong
			}
		} else if (lm === 3) {
			return {
				mau: 3,
				khenTang_Vi: 'Khen tặng học sinh',
				khenTang_En: 'This certificate is proudly presented to',
				hoTen: String(x.HoTen || '').toUpperCase().trim(),
				lop: x.TenLop ? String(x.TenLop).trim() : '',
				noiDung1: noiDung1,
				noiDung2: noiDung2,
				noiDung3: noiDung3,
				ngayThangNam_Vi: ngayThangNam_Vi,
				ngayThangNam_En: ngayThangNam_En,
				soQuyetDinh: soQuyetDinh,
				tenHieuTruong: tenHieuTruong
			}
		} else if (lm === 4) {
			return {
				khenTang_Vi: 'Khen tặng',
				khenTang_En: 'This certificate is proudly presented to',
				lop: x.TenLop ? String(x.TenLop).trim() : '',
				noiDung1: noiDung1,
				noiDung2: noiDung2,
				noiDung3: noiDung3,
				ngayThangNam_Vi: ngayThangNam_Vi,
				ngayThangNam_En: ngayThangNam_En,
				soQuyetDinh: soQuyetDinh,
				tenHieuTruong: tenHieuTruong
			}
		} else {
			// Mẫu 1 mặc định
			return {
				mau: 1,
				khenTang_Vi: 'Khen tặng',
				khenTang_En: 'This certificate is proudly presented to',
				hoTen: '',
				lop: x.TenLop ? String(x.TenLop).trim() : 'LỚP/ CLASS',
				noiDung1: noiDung1,
				noiDung2: noiDung2,
				noiDung3: noiDung3,
				ngayThangNam_Vi: ngayThangNam_Vi,
				ngayThangNam_En: ngayThangNam_En,
				soQuyetDinh: soQuyetDinh,
				tenHieuTruong: tenHieuTruong
			}
		}
	})
	try {
		// Route khớp với CertificateDocx.Api/Controllers/CertGeneratorsController.cs:
		// mẫu 1/2/3 dùng endpoint chuyên biệt, mẫu tập thể dùng model collective riêng.
		const certApiBase = 'https://gencert.iotsoftvn.com/api/cert-generators'
		const apiRoute = lm === 4 ? 'multi-pdf-collective' : `multi-pdf-movement-mau-${lm}`
		const apiUrl = `${certApiBase}/${apiRoute}`
		const response = await fetch(apiUrl, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ certs })
		})
		if (!response.ok) throw new Error('HTTP ' + response.status)
		const blob = await response.blob()
		const url = window.URL.createObjectURL(blob)
		const link = document.createElement('a')
		link.href = url
		const cleanName = (pt?.TenPhongTrao || 'PhongTrao').replace(/[\\\/\?\*\[\]\s]/g, '_')
		link.download = `GiayKhen_${cleanName}.pdf`
		document.body.appendChild(link)
		link.click()
		link.remove()
		// Chỉ tải PDF; không gọi API MarkPrinted vì trạng thái "Đã in" không còn thuộc luồng phong trào thi đua.
		showModuleSnackbarHB('Tải file giấy khen thành công', 'success')
	} catch (error) {
		console.error('exportGiayKhenPTDetail error:', error)
		showModuleSnackbarHB('In giấy khen thất bại: ' + (error?.message || ''), 'error')
	} finally {
		vueData.isLoadingPrint = false
	}
}
// In giấy khen mẫu (mẫu thử) để người dùng xem trước hình thức và phôi giấy khen khi chưa nhập danh sách chi tiết
async function exportGiayKhenMauPT() {
	const pt = vueData.selectedPhongTrao
	if (!pt) {
		showModuleSnackbarHB('Vui lòng chọn một phong trào để in mẫu', 'warning')
		return
	}
	const lm = Number(pt?.LoaiMau) || 1
	vueData.isLoadingPrintSample = true
	const prize = getSelectedPrizeContent(pt)
	const noiDung1 = normalizeHocBongText(prize.DanhHieu_VI || pt.DanhHieu_VI || 'Đã tham gia tích cực phong trào thi đua')
	const noiDung2 = normalizeHocBongText(prize.DanhHieu_EN || pt.DanhHieu_EN || 'For active participation in the school program')
	const noiDung3 = normalizeHocBongText(pt.NamHoc || getPhongTraoSchoolYearLabel())
	const currentDate = new Date()
	const ngayThangNam_Vi = `Ngày ${currentDate.getDate()} tháng ${currentDate.getMonth() + 1} năm ${currentDate.getFullYear()}`
	const monthsEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
	const ngayThangNam_En = `${monthsEn[currentDate.getMonth()]} ${currentDate.getDate()}, ${currentDate.getFullYear()}`
	const soQuyetDinh = 'NO: 01/QĐ-KT'
	const tenHieuTruong = 'Hoàng Thị Diễm Trang'
	let cert
	if (lm === 2 || lm === 3) {
		cert = {
			mau: lm,
			khenTang_Vi: 'Khen tặng học sinh',
			khenTang_En: 'This certificate is proudly presented to',
			hoTen: 'NGUYỄN VĂN A (MẪU THỬ)',
			// Mẫu phôi không suy diễn lớp từ KhoiID; lớp chỉ được lấy khi in danh sách khen thưởng thật.
			lop: '',
			noiDung1: noiDung1,
			noiDung2: noiDung2,
			noiDung3: noiDung3,
			ngayThangNam_Vi: ngayThangNam_Vi,
			ngayThangNam_En: ngayThangNam_En,
			soQuyetDinh: soQuyetDinh,
			tenHieuTruong: tenHieuTruong
		}
	} else if (lm === 4) {
		cert = {
			khenTang_Vi: 'Khen tặng',
			khenTang_En: 'This certificate is proudly presented to',
			// Mẫu phôi không suy diễn lớp từ KhoiID; lớp chỉ được lấy khi in danh sách khen thưởng thật.
			lop: '',
			noiDung1: noiDung1,
			noiDung2: noiDung2,
			noiDung3: noiDung3,
			ngayThangNam_Vi: ngayThangNam_Vi,
			ngayThangNam_En: ngayThangNam_En,
			soQuyetDinh: soQuyetDinh,
			tenHieuTruong: tenHieuTruong
		}
	} else {
		// Mẫu 1
		cert = {
			mau: 1,
			khenTang_Vi: 'Khen tặng',
			khenTang_En: 'This certificate is proudly presented to',
			hoTen: '',
			// Mẫu phôi không có lớp được nhập; để trống để API không in nhầm lớp suy diễn từ khối.
			lop: '',
			noiDung1: noiDung1,
			noiDung2: noiDung2,
			noiDung3: noiDung3,
			ngayThangNam_Vi: ngayThangNam_Vi,
			ngayThangNam_En: ngayThangNam_En,
			soQuyetDinh: soQuyetDinh,
			tenHieuTruong: tenHieuTruong
		}
	}
	try {
		const certApiBase = 'https://gencert.iotsoftvn.com/api/cert-generators'
		const apiRoute = lm === 4 ? 'multi-pdf-collective' : `multi-pdf-movement-mau-${lm}`
		const apiUrl = `${certApiBase}/${apiRoute}`
		const response = await fetch(apiUrl, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ certs: [cert] })
		})
		if (!response.ok) throw new Error('HTTP ' + response.status)
		const blob = await response.blob()
		const url = window.URL.createObjectURL(blob)
		const link = document.createElement('a')
		link.href = url
		const cleanName = (pt?.TenPhongTrao || 'PhongTrao').replace(/[\\\/\?\*\[\]\s]/g, '_')
		link.download = `GiayKhen_MauThu_${cleanName}.pdf`
		document.body.appendChild(link)
		link.click()
		link.remove()
		showModuleSnackbarHB('Tải file giấy khen mẫu thành công', 'success')
	} catch (error) {
		console.error('exportGiayKhenMauPT error:', error)
		showModuleSnackbarHB('In giấy khen mẫu thất bại: ' + (error?.message || ''), 'error')
	} finally {
		vueData.isLoadingPrintSample = false
	}
}
async function onTabChange(tab) {
	syncModuleRoleState()
	if (tab === 'HOC_BONG' && vueData.canViewHocBong === false) {
		vueData.activeTab = 'PHONG_TRAO'
		showModuleSnackbarHB('Giáo viên chủ nhiệm chỉ được truy cập Phong trào thi đua', 'warning')
		return
	}
	if (tab) {
		vueData.activeTab = tab
	}
	if (vueData.activeTab === 'PHONG_TRAO') {
		await reloadPhongTraoMaster()
	} else {
		await reloadHocBongList()
	}
}
// Global Vue State & Exports
const requestedTab = new URLSearchParams(window.location.search || '').get('tab')
vueData.activeTab = requestedTab === 'PHONG_TRAO' || requestedTab === 'HOC_BONG'
	? requestedTab
	: (vueData.activeTab || 'HOC_BONG')
vueData.syncModuleRoleState = syncModuleRoleState
syncModuleRoleState()
vueData.DSAllHocSinh = []
vueData.AddHocSinhSelected = null
vueData.DelHocSinhSelected = []
vueData.AddMucHocBong = '25% học phí học kì I'
// Tab Phong Trao State
vueData.DSPhongTraoMaster = []
vueData.selectedPhongTrao = null
// Giải đang chọn được giữ riêng với group để reload không làm bảng chi tiết quay về toàn bộ group.
vueData.selectedPrizeName = ''
// Giữ các ID đã được server xác nhận xóa để GET stale/cache không đưa dòng cũ trở lại trong phiên hiện tại.
vueData.deletedPhongTraoDetailIds = []
// Cache scope theo tài khoản + niên khóa để reload bảng không gọi lại danh sách lớp/học sinh dư thừa.
vueData.GVCNPhongTraoScopeKey = ''
vueData.DSHocBongDetail = []
vueData.isLoadingMaster = false
vueData.isLoadingDetail = false
// Ba mẫu khác nhau ở dữ liệu xuất trên giấy: Mẫu 1 chỉ có lớp, Mẫu 2 in sẵn HS + lớp, Mẫu 3 do GVCN chọn HS trong lớp chủ nhiệm.
vueData.DSLoaiMau = [
	{ title: 'Mẫu 1 — Chỉ có lớp / Class only', value: 1 },
	{ title: 'Mẫu 2 — In sẵn tên học sinh và lớp', value: 2 },
	{ title: 'Mẫu 3 — GVCN chọn học sinh lớp chủ nhiệm', value: 3 },
	{ title: 'Mẫu tập thể — In theo lớp / Class', value: 4 }
]
// Master Form State
vueData.IsShowDialogAddPhongTraoMaster = false
vueData.IsEditingPhongTrao = false
vueData.MasterForm_PhongTraoID = 0
vueData.MasterForm_TenPhongTrao = ''
vueData.MasterForm_LoaiMau = 1
vueData.MasterForm_DanhHieu_VI = ''
vueData.MasterForm_DanhHieu_EN = ''
vueData.MasterForm_NamHoc = getPhongTraoSchoolYearLabel()
vueData.MasterForm_DongNoiDung = createDefaultPhongTraoDongs()
vueData.DSNgonNguDong = [
	{ title: 'Tiếng Việt', value: 'VI' },
	{ title: 'Tiếng Anh', value: 'EN' },
	{ title: 'Song ngữ / khác', value: 'ALL' }
]
vueData.MasterForm_KhoiItem = null
vueData.MasterForm_GhiChu = ''
vueData.isLoadingSavePhongTrao = false
vueData.IsShowDialogDelPhongTraoMaster = false
vueData.itemPhongTraoToDelete = null
vueData.isLoadingDelPhongTrao = false
// Detail Form State
vueData.IsShowDialogAddChiTietPT = false
vueData.DetailForm_HocSinhSelected = null
vueData.DetailForm_TenLop = ''
vueData.DetailForm_KhoiItem = null
vueData.DetailForm_DanhHieu_VI = ''
vueData.DetailForm_DanhHieu_EN = ''
vueData.DetailForm_VaoSo = null
vueData.DetailForm_NgayCap_VI = ''
vueData.DetailForm_NgayCap_EN = ''
vueData.DetailForm_SoQuyetDinhVaKhenThuong = ''
vueData.isLoadingAddChiTietPT = false
vueData.IsShowDialogDelChiTietPT = false
vueData.DelChiTietPTSelected = []
vueData.isLoadingDelChiTietPT = false
// Bind methods
vueData.onTabChange = onTabChange
vueData.renderDSHocBong = renderDSHocBong
vueData.renderDSHocSinhChange = renderDSHocSinhChange
vueData.onExportExcel = onExportExcel
vueData.onSave = onSave
vueData.confirmSaveHocBong = confirmSaveHocBong
vueData.exportGiayChungNhanHocBong = exportGiayChungNhanHocBong
vueData.openAddHocSinh = openAddHocSinh
vueData.submitAddHocSinh = submitAddHocSinh
vueData.submitDelHocSinh = submitDelHocSinh
vueData.reloadHocBongList = reloadHocBongList
// Phong Trao Master & Detail methods
vueData.reloadPhongTraoMaster = reloadPhongTraoMaster
vueData.selectPhongTrao = selectPhongTrao
vueData.reloadPhongTraoDetail = reloadPhongTraoDetail
vueData.renderDSPhongTraoDetail = renderDSPhongTraoDetail
vueData.openAddPhongTraoMaster = openAddPhongTraoMaster
vueData.openEditPhongTraoMaster = openEditPhongTraoMaster
vueData.addMasterDongNoiDung = addMasterDongNoiDung
vueData.removeMasterDongNoiDung = removeMasterDongNoiDung
vueData.submitSavePhongTraoMaster = submitSavePhongTraoMaster
vueData.openDelPhongTraoMaster = openDelPhongTraoMaster
vueData.submitDelPhongTraoMaster = submitDelPhongTraoMaster
vueData.openAddChiTietPT = openAddChiTietPT
vueData.openEditChiTietPT = openEditChiTietPT
vueData.onSelectEditDetailRecord = onSelectEditDetailRecord
vueData.submitSaveEditChiTietPT = submitSaveEditChiTietPT
vueData.submitAddChiTietPT = submitAddChiTietPT
vueData.submitDelChiTietPT = submitDelChiTietPT
vueData.onDetailKhoiChange = onDetailKhoiChange
vueData.onDetailLopChange = onDetailLopChange
vueData.onEditDetailKhoiChange = onEditDetailKhoiChange
vueData.onEditDetailLopChange = onEditDetailLopChange
vueData.onEditDetailHocSinhChange = onEditDetailHocSinhChange
vueData.onSavePTDetail = onSavePTDetail
vueData.confirmSavePTDetail = confirmSavePTDetail
vueData.onExportExcelPTDetail = onExportExcelPTDetail
vueData.exportGiayKhenPTDetail = exportGiayKhenPTDetail
vueData.exportGiayKhenMauPT = exportGiayKhenMauPT
vueData.isLoadingPrintSample = false
vueData.DSAllLop = []
vueData.DSFilteredLop = []
vueData.DSFilteredHocSinh = []
vueData.DetailForm_LopSelected = []
vueData.DetailForm_LopItem = null
if (!vueData.KhoiItem || vueData.KhoiItem.value === null || vueData.KhoiItem.value === undefined) {
	vueData.KhoiItem = (vueData.DSKhoi || []).find(x => x.value === 0) || { title: 'Tất cả', value: 0, CapID: 0 }
}
vueData.Semester = vueData.Semester || { title: 'Học kì 1', value: 1 }
setTimeout(() => {
	if (!vueData.KhoiItem || vueData.KhoiItem.value === null || vueData.KhoiItem.value === undefined) {
		vueData.KhoiItem = (vueData.DSKhoi || []).find(x => x.value === 0) || { title: 'Tất cả', value: 0, CapID: 0 }
	}
	if (vueData.activeTab === 'PHONG_TRAO') {
		if (vueData.reloadPhongTraoMaster) vueData.reloadPhongTraoMaster()
	} else {
		if (vueData.reloadHocBongList) vueData.reloadHocBongList()
	}
}, 300)