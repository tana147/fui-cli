function showModuleSnackbarDKLT(message, color = 'warning') {
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
function renderDSLop() {
	const seen = new Set()
	const out = []
	;(vueData.DSLop || []).forEach(x => {
		const lopID = x.LopID
		const monHocID = x.MonHocID
		if (!lopID) return
		const key = lopID + '_' + monHocID
		if (seen.has(key)) return
		seen.add(key)
		const tenMonHoc = x.TenMonHoc_HienThi || x.TenMonHoc || x.MonHocName || x.MonHocName_HienThi || ''
		out.push({
			LopID: lopID,
			MonHocID: monHocID,
			// GiaoVienLop_Get_By_GiaoVienID trả về lớp thường từ tblLop và
			// lớp nhóm từ tblNhom. Giữ nguyên các khóa nhận diện để không
			// biến lớp thường thành lớp nhóm chỉ vì trùng tên hiển thị.
			NhomID: x.NhomID ?? x.LopNhomID ?? x.NhomLopID ?? null,
			LoaiLop: x.LoaiLop ?? x.Loai ?? x.IsLopNhom ?? null,
			TenLop: x.TenLop || x.TenLop_HienThi || x.TenNhom || '',
			KhoiID: x.KhoiID,
			TenMonHoc: tenMonHoc,
			TenHienThi: (x.TenLop || '') + (tenMonHoc ? ' - ' + tenMonHoc : '')
		})
	})
	// Lớp chủ nhiệm (GVCN đăng ký thiết bị): TKB hiển thị tên lớp gốc (vd "11B"), khác với các
	// lớp-nhóm theo tổ hợp môn ở trên (vd "11B1"/"11B2") nên phải nạp riêng từ tblLop.GVCN.
	;(vueData.DSLopChuNhiem || []).forEach(x => {
		const lopID = x.LopID
		if (!lopID) return
		const key = lopID + '_CN'
		if (seen.has(key)) return
		seen.add(key)
		out.push({
			LopID: lopID,
			MonHocID: 0,
			IsLopChuNhiem: true,
			TenLop: x.TenLop || '',
			KhoiID: x.KhoiID,
			TenMonHoc: 'GVCN đăng ký thiết bị',
			TenHienThi: (x.TenLop || '') + ' - GVCN đăng ký thiết bị'
		})
	})
	out.sort((a, b) => String(a.TenLop).localeCompare(String(b.TenLop)))
	vueData.DSLop_HienThi = out
}
function getThu(dateStr) {
	if (!dateStr) return null
	const d = new Date(dateStr)
	const dow = d.getDay() // 0=CN,1=T2,...6=T7
	return dow === 0 ? 8 : dow + 1 // 2..7 = Thứ 2..7, 8 = Chủ nhật
}
function tenThu(thu) {
	if (thu === 8) return 'CN'
	return 'Thứ ' + thu
}
function computeDeadline(ngayApDung, thu) {
	const d = new Date(ngayApDung)
	const dow = d.getDay()
	const diffToMonday = dow === 0 ? -6 : 1 - dow
	const monday = new Date(d)
	monday.setDate(d.getDate() + diffToMonday)
	if (thu === 2) {
		const sunday = new Date(monday)
		sunday.setDate(monday.getDate() - 1)
		sunday.setHours(12, 0, 0, 0)
		return sunday
	}
	monday.setHours(8, 0, 0, 0)
	return monday
}
function canhBaoTreHan() {
	if (!vueData.NgayApDung) return false
	const thu = getThu(vueData.NgayApDung)
	if (!thu) return false
	const deadline = computeDeadline(vueData.NgayApDung, thu)
	return new Date() > deadline
}
function tenBuoi(b) {
	return { 1: 'Sáng', 2: 'Chiều', 3: 'Tối' }[b] || ''
}
// GVCN được đăng ký thêm các tiết không có trong TKB cá nhân; các tiết này
// luôn gắn với lớp chủ nhiệm và không cần biết giáo viên/môn đang dạy.
function coLopChuNhiem() {
	return (vueData.DSLopChuNhiem || []).some(x => Number(x.LopID) > 0)
}
function getLopChuNhiemItem() {
	const item = (vueData.DSLop_HienThi || []).find(x => x.IsLopChuNhiem)
	if (item) return item
	const raw = (vueData.DSLopChuNhiem || []).find(x => Number(x.LopID) > 0)
	if (!raw) return null
	return {
		LopID: raw.LopID,
		MonHocID: 0,
		IsLopChuNhiem: true,
		TenLop: raw.TenLop || '',
		KhoiID: raw.KhoiID,
		TenMonHoc: 'GVCN đăng ký thiết bị',
		TenHienThi: (raw.TenLop || '') + ' - GVCN đăng ký thiết bị'
	}
}
function isDangKyCuaLopChuNhiem(dangKy) {
	return (vueData.DSLopChuNhiem || []).some(lop =>
		(Number(dangKy.LopID) > 0 && Number(dangKy.LopID) === Number(lop.LopID)) ||
		(normalizeClassLookupKey(dangKy.TenLop) && normalizeClassLookupKey(dangKy.TenLop) === normalizeClassLookupKey(lop.TenLop))
	)
}
function isTietGVCNDaDangKy(thuKey, buoi, tiet) {
	const ngay = tinhNgayTuThuKey(thuKey)
	return (vueData.DSDangKy || []).some(dangKy =>
		isDangKyCuaLopChuNhiem(dangKy) &&
		Number(dangKy.Buoi) === Number(buoi) &&
		Number(dangKy.TietBatDau) <= Number(tiet) &&
		Number(dangKy.TietKetThuc) >= Number(tiet) &&
		normalizeDateKey(dangKy.NgayApDung) === ngay
	)
}
function chonTuanTKBHienTai() {
	const active = (vueData.DSTuan || []).find(x => x.Is_Active === 1)
	vueData.TuanXemTKB = active || vueData.DSTuan?.[0] || null
}
function tinhNgayDauTuanTKB() {
	const ngayBatDau = vueData.TuanXemTKB?.NgayBatDau
	if (!ngayBatDau) return ''
	// NgayBatDau dạng "2026-08-03T00:00:00" hoặc "2026-08-03"
	return String(ngayBatDau).slice(0, 10)
}
function parseTKBCell(html) {
	if (!html) return null
	const match = html.match(/<b>\s*([^<]+)<\/b>/)
	const boldText = match ? match[1].trim() : ''
	const withoutBold = html.replace(/<b>[\s\S]*?<\/b>/, '')
	const parts = withoutBold.split('<br>').map(s => s.replace(/<[^>]+>/g, '').trim()).filter(Boolean)
	// TKB quansinh có 2 dạng: <b>Lớp</b><br>Môn và
	// <b>Lớp - Môn</b>. Chuẩn hóa cả hai để tra đúng tblLop/tblNhom.
	const inlineParts = boldText.split(/\s+-\s+/)
	const tenLop = inlineParts[0] || boldText
	const tenMon = parts[0] || inlineParts.slice(1).join(' - ')
	return { TenLop: tenLop, TenMon: tenMon }
}
function renderTKB() {
	const raw = vueData.TKBRaw || []
	vueData.TKBTuanInfo = (raw[0] && raw[0][0]) || null
	const lich = raw[1] || []
	const thuKeys = ['2', '3', '4', '5', '6', '7', '1']
	// Với GVCN, bổ sung đủ 10 dòng sáng/chiều để mọi tiết trong tuần đều có
	// thể bấm chọn; ô không có lịch vẫn để trống và chỉ mang cờ IsTietGVCN.
	const rows = coLopChuNhiem()
		? Array.from({ length: 10 }, (_, index) => {
			const buoi = index < 5 ? 1 : 2
			const tiet = index % 5 + 1
			return lich.find(row => Number(row.Buoi) === buoi && Number(row.Tiet) === tiet) || { Buoi: buoi, Tiet: tiet }
		})
		: lich
	vueData.DSTKB = rows
		.filter(row => Number(row.Buoi) !== 3) // ẩn buổi Tối - trường chưa có lớp học tối
		.map(row => {
			const cells = thuKeys.map(k => {
				const parsed = parseTKBCell(row[k])
				const isTietGVCN = !parsed && coLopChuNhiem()
				return {
					ThuKey: k,
					TenLop: parsed?.TenLop || '',
					TenMon: parsed?.TenMon || '',
					CoTiet: !!parsed || isTietGVCN,
					IsTietGVCN: isTietGVCN,
				}
			})
			return { Buoi: Number(row.Buoi), Tiet: Number(row.Tiet), TenBuoi: tenBuoi(Number(row.Buoi)), Cells: cells }
		})
	danhDauDaDangKyTKB()
}
// Đánh dấu các ô TKB trùng với đăng ký đã lưu (lớp + ngày + buổi + tiết) để hiện icon/màu riêng.
function danhDauDaDangKyTKB() {
	const dsDangKy = vueData.DSDangKy || []
	;(vueData.DSTKB || []).forEach(row => {
		row.Cells.forEach(cell => {
			if (!cell.CoTiet) {
				cell.IsDaDangKy = false
				return
			}
			const ngayCell = tinhNgayTuThuKey(cell.ThuKey)
			cell.IsDaDangKy = dsDangKy.some(dk => {
				const dungLop = cell.IsTietGVCN
					? isDangKyCuaLopChuNhiem(dk)
					// Sau khi lớp TKB 10A được tách lưu thành 10A1/10A2, ô TKB 10A
					// vẫn phải nhận biết các đăng ký của từng lớp thành phần.
					: normalizeClassLookupKey(dk.TenLop) === normalizeClassLookupKey(cell.TenLop) ||
						(isNhomCuaLopGoc(cell.TenLop, dk.TenLop) && isMonHocTuongThich(cell.TenMon, dk.TenMonHoc))
				return dungLop &&
					Number(dk.Buoi) === Number(row.Buoi) &&
					Number(dk.TietBatDau) <= Number(row.Tiet) && Number(dk.TietKetThuc) >= Number(row.Tiet) &&
					normalizeDateKey(dk.NgayApDung) === ngayCell
			})
		})
	})
	vueData.DSTKB = [...vueData.DSTKB]
}
function normalizeDateKey(value) {
	const text = String(value || '').trim()
	const dateParts = text.match(/^(\d{2})\/(\d{2})\/(\d{4})/)
	return dateParts ? `${dateParts[3]}-${dateParts[2]}-${dateParts[1]}` : text.slice(0, 10)
}
function keyTKB(row, cell) {
	return row.Buoi + '_' + row.Tiet + '_' + cell.ThuKey
}
function tinhNgayTuThuKey(thuKey) {
	const tuNgay = vueData.TKBTuanInfo?.TuNgay // "dd/mm/yyyy", là Thứ 2 của tuần
	if (!tuNgay) return null
	const [d, m, y] = tuNgay.split('/').map(Number)
	const base = new Date(y, m - 1, d)
	const offsetMap = { '2': 0, '3': 1, '4': 2, '5': 3, '6': 4, '7': 5, '1': 6 }
	base.setDate(base.getDate() + (offsetMap[thuKey] ?? 0))
	const pad = n => String(n).padStart(2, '0')
	return `${base.getFullYear()}-${pad(base.getMonth() + 1)}-${pad(base.getDate())}`
}
function normalizeLookupText(value) {
	let text = String(value || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/&/g, ' va ').replace(/[^a-z0-9]+/g, ' ').trim().replace(/\s+/g, ' ')
	const aliases = {
		// TKB ghi "TA tích hợp...", còn danh mục môn LMS dùng tên chuẩn "Ngoại ngữ".
		'ta tich hop gvnn': 'ngoai ngu',
		'ta tich hop gvvn': 'ngoai ngu',
		'gd kt va pl': 'giao duc kinh te va phap luat',
		'gdkt va pl': 'giao duc kinh te va phap luat',
		// TKB ghi "Chuyên đề HT KT&PL", còn phân công trên LMS dùng tên môn đầy đủ.
		'chuyen de ht kt va pl': 'giao duc kinh te va phap luat',
		'gdcd': 'giao duc cong dan',
		'hd trai nghiem': 'hoat dong trai nghiem'
	}
	Object.keys(aliases).forEach(key => {
		text = text.replace(new RegExp('(^| )' + key + '(?= |$)', 'g'), '$1' + aliases[key])
	})
	return text.replace(/\s+/g, ' ').trim()
}
function normalizeClassLookupKey(value) {
	// TKB dùng 11AV2, còn tên nhóm LMS có thể là 26-11AV2.
	return normalizeLookupText(value).replace(/^\d+\s*-\s*/, '').replace(/^\d+\s+/, '').replace(/\s+/g, '')
}
function getBaseClassLookupKey(value) {
	const classKey = normalizeClassLookupKey(value)
	const match = classKey.match(/^(\d+[a-z]+)\d$/)
	return match ? match[1] : ''
}
function scoreSubjectMatch(source, candidate) {
	const sourceTokens = new Set(normalizeLookupText(source).split(' ').filter(Boolean))
	const candidateTokens = new Set(normalizeLookupText(candidate).split(' ').filter(Boolean))
	let score = 0
	sourceTokens.forEach(token => {
		if (candidateTokens.has(token)) score += token.length >= 2 ? 2 : 1
	})
	return score
}
function isMonHocTuongThich(source, candidate) {
	const sourceTokens = normalizeLookupText(source).split(' ').filter(Boolean)
	const candidateTokens = new Set(normalizeLookupText(candidate).split(' ').filter(Boolean))
	// Cho phép hậu tố khối/lớp ("Ngữ văn" ↔ "Ngữ văn 10"), nhưng không
	// gộp nhầm "Chuyên đề HT Văn" chỉ vì cùng có từ "văn".
	return sourceTokens.length > 0 && sourceTokens.every(token => candidateTokens.has(token))
}
function isNhomCuaLopGoc(tenLopGoc, tenLopNhom) {
	const lopGoc = normalizeClassLookupKey(tenLopGoc)
	const lopNhom = normalizeClassLookupKey(tenLopNhom)
	// TKB có thể ghi lớp gốc "10A", trong khi phân công bộ môn trả
	// các nhóm "10A1", "10A2". Chỉ nhận hậu tố là số để không gộp nhầm
	// các lớp có tên gần giống nhưng không cùng lớp gốc.
	return Boolean(lopGoc && new RegExp('^' + lopGoc.replace(/[.*+?^${}()|[\\]\\]/g, '\\$&') + '\\d+$').test(lopNhom))
}
function dienFormTuTiet(item) {
	if (item.IsTietGVCN) {
		const lopChuNhiem = getLopChuNhiemItem()
		if (!lopChuNhiem) {
			showModuleSnackbarDKLT('Không xác định được lớp chủ nhiệm để đăng ký', 'warning')
			return false
		}
		vueData.LopItem = lopChuNhiem
		vueData.Buoi = item.Buoi
		vueData.TietBatDau = item.Tiet
		vueData.TietKetThuc = item.Tiet
		vueData.NgayApDung = item.NgayApDung
		vueData.TKBKeyDangChon = item.key
		return true
	}
	const tenLop = normalizeClassLookupKey(item.TenLop)
	const tenMon = normalizeLookupText(item.TenMon)
	const dsLop = vueData.DSLop_HienThi || []
	const exactClassCandidates = dsLop.filter(x => normalizeClassLookupKey(x.TenLop) === tenLop)
	// Một số tiết TKB ghi lớp nhóm theo môn (10F2), trong khi phân công LMS lưu lớp gốc (10F).
	// Chỉ thử tên lớp gốc khi không có lớp khớp chính xác; bên dưới vẫn phải khớp môn mới chọn.
	const baseClassKey = exactClassCandidates.length ? '' : getBaseClassLookupKey(item.TenLop)
	const baseClassCandidates = baseClassKey
		? dsLop.filter(x => normalizeClassLookupKey(x.TenLop) === baseClassKey)
		: []
	const usedBaseClassFallback = exactClassCandidates.length === 0 && baseClassCandidates.length > 0
	const candidates = exactClassCandidates.length ? exactClassCandidates : baseClassCandidates
	const exactCandidates = candidates.filter(x => normalizeLookupText(x.TenMonHoc) === tenMon)
	const exact = exactCandidates.find(x => !x.NhomID && !x.IsLopNhom && !x.LoaiLop) || exactCandidates[0]
	const scored = candidates.map(x => ({ item: x, score: scoreSubjectMatch(tenMon, x.TenMonHoc) })).sort((a, b) => b.score - a.score)
	const bestScore = scored[0]?.score || 0
	const bestMatches = scored.filter(x => x.score === bestScore && x.score > 0)
	// Khi TKB là lớp thường (tblLop), ưu tiên bản ghi không có NhomID.
	// Chỉ yêu cầu chọn lớp nhóm khi thực sự có nhiều bản ghi cùng môn.
	const normalCandidates = candidates.filter(x => !x.NhomID && !x.IsLopNhom && !x.LoaiLop)
	// Tạm thời không chặn luồng đăng ký khi API trả nhiều bản ghi lớp nhóm.
	// Ưu tiên lớp thường; nếu chưa có metadata phân biệt tblLop/tblNhom thì
	// dùng bản ghi đầu tiên để giáo viên vẫn thao tác được.
	let found = exact || (bestMatches.length === 1 ? bestMatches[0].item :
		(usedBaseClassFallback ? null : (normalCandidates[0] || candidates[0] || null)))
	// Không có lớp trùng tên: gộp các lớp thành phần thuộc lớp gốc và đúng môn.
	// Ví dụ TKB "10A - Ngữ văn", phân công "10A1 - Ngữ văn" và
	// "10A2 - Ngữ văn". Đây là các LopID thực, không phải lớp 10A giả.
	if (!found) {
		const nhomCungLopCungMon = dsLop.filter(x =>
			// Có trường dữ liệu lưu 10A1/10A2 là tblNhom, có trường lại
			// là hai tblLop thường. Cả hai đều là lớp thực tế cần gộp.
			isNhomCuaLopGoc(item.TenLop, x.TenLop) &&
			// Tên môn giữa TKB và phân công có thể khác hậu tố, ví dụ
			// "Ngữ văn" và "Ngữ văn 10".
			isMonHocTuongThich(tenMon, x.TenMonHoc)
		)
		if (nhomCungLopCungMon.length) {
			const firstNhom = nhomCungLopCungMon[0]
			const tenCacNhom = nhomCungLopCungMon.map(x => x.TenLop).filter(Boolean).join(' + ')
			found = Object.assign({}, firstNhom, {
				TenLop: item.TenLop,
				// Chỉ là nhãn màn GVBM để giáo viên biết các lớp nào được gộp.
				// TenLop vẫn phải là lớp gốc để các phân hệ GVCN/BGH tra cùng bản ghi.
				TenHienThi: item.TenLop + (tenCacNhom ? ' (gồm ' + tenCacNhom + ')' : '') + (item.TenMon ? ' - ' + item.TenMon : ''),
				IsLopGop: true,
				DSLopThanhPhan: nhomCungLopCungMon,
			})
		}
	}
	// Lớp thay có thể có trong TKB nhưng chưa có phân công GiaoVienLop.
	// Chỉ tự tra nhóm khi tên lớp khớp duy nhất; nếu trùng nhóm/môn thì chặn để không dùng nhầm NhomID.
	if (!found) {
		const seenGroups = new Set()
		const groupCandidates = (vueData.DSNhomAV || []).filter(group => {
			const nhomID = group.NhomID || group.LopID
			if (!nhomID || normalizeClassLookupKey(group.TenNhom || group.TenLop) !== tenLop) return false
			const key = String(nhomID) + '_' + String(group.MonHocID || '')
			if (seenGroups.has(key)) return false
			seenGroups.add(key)
			return true
		}).map(group => ({
			NhomID: group.NhomID || group.LopID,
			MonHocID: group.MonHocID,
			KhoiID: group.KhoiID,
			TenMonHoc: group.TenMonHoc_HienThi || group.TenMonHoc || '',
		}))
		const subjectMatches = groupCandidates.filter(group =>
			normalizeLookupText(group.TenMonHoc) === tenMon || isMonHocTuongThich(tenMon, group.TenMonHoc)
		)
		const matchedGroup = subjectMatches.length === 1
			? subjectMatches[0]
			: (!tenMon && groupCandidates.length === 1 ? groupCandidates[0] : null)
		if (matchedGroup) {
			found = {
				LopID: matchedGroup.NhomID,
				NhomID: matchedGroup.NhomID,
				IsLopNhom: true,
				IsScheduleFallback: true,
				TenLop: item.TenLop,
				KhoiID: matchedGroup.KhoiID,
				MonHocID: matchedGroup.MonHocID,
				TenMonHoc: matchedGroup.TenMonHoc || item.TenMon,
				TenHienThi: item.TenLop + (item.TenMon ? ' - ' + item.TenMon : '')
			}
		} else if (groupCandidates.length) {
			showModuleSnackbarDKLT(`Không xác định duy nhất được nhóm và môn của lớp "${item.TenLop}" từ thời khóa biểu`, 'warning')
			return false
		}
	}
	if (found) {
		vueData.LopItem = found
	} else {
		const message = `Không tìm thấy lớp "${item.TenLop}" trong danh sách lớp bạn dạy — vui lòng chọn tay`
		showModuleSnackbarDKLT(message, 'warning')
		return false
	}
	vueData.Buoi = item.Buoi
	vueData.TietBatDau = item.Tiet
	vueData.TietKetThuc = item.Tiet
	vueData.NgayApDung = item.NgayApDung
	vueData.TKBKeyDangChon = item.key
	return true
}
function onChonTietTKB(row, cell) {
	if (!cell.CoTiet) return false
	if (cell.IsDaDangKy) {
		showModuleSnackbarDKLT('Tiết này đã được đăng ký, không thể đăng ký lại', 'warning')
		return false
	}
	if (cell.IsBiTrungLich) {
		showModuleSnackbarDKLT('Tiết này đã có đăng ký trùng lịch', 'warning')
		return false
	}
	const key = keyTKB(row, cell)
	const daCo = (vueData.TKBQueue || []).find(x => x.key === key)
	if (daCo) {
		return dienFormTuTiet(daCo)
	}
	const item = {
		key,
		Buoi: row.Buoi,
		Tiet: row.Tiet,
		ThuKey: cell.ThuKey,
		IsTietGVCN: !!cell.IsTietGVCN,
		TenLop: cell.TenLop,
		TenMon: cell.TenMon,
		NgayApDung: tinhNgayTuThuKey(cell.ThuKey)
	}
	vueData.TKBQueue = [...(vueData.TKBQueue || []), item]
	if (!dienFormTuTiet(item)) {
		vueData.TKBQueue = (vueData.TKBQueue || []).filter(x => x.key !== key)
		return false
	}
	return true
}
function isTietDaChon(row, cell) {
	const key = keyTKB(row, cell)
	return (vueData.TKBQueue || []).some(x => x.key === key)
}
function boChonTietTKB(item) {
	vueData.TKBQueue = (vueData.TKBQueue || []).filter(x => x.key !== item.key)
	if (vueData.TKBKeyDangChon === item.key) vueData.TKBKeyDangChon = null
}
function initHocSinhThietBi() {
	vueData.HocSinhThietBi = (vueData.DSHocSinhLop || []).map(hs => ({
		HocSinhID: hs.HocSinhID,
		SoDanhBo: hs.SoDanhBo,
		HoTen: hs.HoTen,
		// Giữ LopID nguồn khi danh sách trên UI được gộp từ nhiều lớp.
		DSLopNguon: hs.DSLopNguon || [],
		IsChon: true,
		GhiChu: '',
		ThietBiChon: ['Laptop']
	}))
}
function chonTatCaHocSinh() {
	(vueData.HocSinhThietBi || []).forEach(x => { x.IsChon = true })
}
function boChonTatCaHocSinh() {
	(vueData.HocSinhThietBi || []).forEach(x => { x.IsChon = false })
}
function toggleChonHocSinh(hs) {
	hs.IsChon = !hs.IsChon
}
function isCotThietBiChonHet(loai) {
	const list = (vueData.HocSinhThietBi || []).filter(x => x.IsChon)
	return list.length > 0 && list.every(x => x.ThietBiChon.includes(loai))
}
function toggleCotThietBi(loai) {
	const list = (vueData.HocSinhThietBi || []).filter(x => x.IsChon)
	if (!list.length) return
	const chonHet = isCotThietBiChonHet(loai)
	list.forEach(x => {
		const idx = x.ThietBiChon.indexOf(loai)
		if (chonHet) {
			if (idx > -1) x.ThietBiChon.splice(idx, 1)
		} else {
			if (idx === -1) x.ThietBiChon.push(loai)
		}
	})
}
function toggleThietBi(hs, loai) {
	const idx = hs.ThietBiChon.indexOf(loai)
	if (idx > -1) hs.ThietBiChon.splice(idx, 1)
	else hs.ThietBiChon.push(loai)
}
function formatNgay(ngayStr) {
	if (!ngayStr) return ''
	const d = new Date(ngayStr)
	const pad = n => String(n).padStart(2, '0')
	return `${pad(d.getDate())}/${pad(d.getMonth() + 1)}/${d.getFullYear()}`
}
function renderDSDangKy() {
	vueData.DSDangKy = (vueData.DSDangKy || []).map(x => ({
		...x,
		ThuHienThi: tenThu(x.Thu),
		BuoiHienThi: tenBuoi(x.Buoi),
		TietHienThi: Number(x.TietBatDau) === Number(x.TietKetThuc) ? String(x.TietBatDau) : x.TietBatDau + '-' + x.TietKetThuc,
		LichHienThi: tenThu(x.Thu) + ' • ' + tenBuoi(x.Buoi) + ' • Tiết ' + (Number(x.TietBatDau) === Number(x.TietKetThuc) ? String(x.TietBatDau) : x.TietBatDau + '-' + x.TietKetThuc),
		NgayApDungHienThi: formatNgay(x.NgayApDung),
		TreHanHienThi: x.IsTreHan ? 'Trễ hạn' : ''
	}))
	danhDauDaDangKyTKB()
}
function danhDauTietBiTrungLich() {
	const key = vueData.TKBKeyDangChon
	if (!key) return
	const parts = String(key).split('_')
	const buoi = Number(parts[0])
	const tiet = Number(parts[1])
	const thuKey = parts[2]
	;(vueData.DSTKB || []).forEach(row => {
		if (row.Buoi !== buoi || row.Tiet !== tiet) return
		;(row.Cells || []).forEach(cell => {
			if (cell.ThuKey === thuKey) cell.IsBiTrungLich = true
		})
	})
	vueData.DSTKB = [...(vueData.DSTKB || [])]
	vueData.TKBQueue = (vueData.TKBQueue || []).filter(item => item.key !== key)
	vueData.TKBKeyDangChon = null
}
function getLopIDDangKy() {
	const lopItem = vueData.LopItem
	if (lopItem?.IsLopGop) {
		// Học sinh của mỗi nhóm vẫn mang LopID số của lớp gốc. Chỉ lưu khi
		// tất cả nhóm thực sự cùng một lớp gốc, tránh ghi nhầm sang lớp khác.
		const lopIDs = [...new Set((vueData.DSHocSinhLop || [])
			.map(x => Number(x.LopID))
			.filter(x => Number.isInteger(x) && x > 0))]
		return lopIDs.length === 1 ? lopIDs[0] : null
	}
	if (!lopItem?.NhomID) return Number(lopItem?.LopID) || null
	// tblDangKyMangLaptop.LopID là INT; lớp nhóm dùng LopID dạng Nxxxx.
	// tblHocSinhNhom vẫn trả về LopID số của lớp gốc để lưu đăng ký.
	return (vueData.DSHocSinhLop || [])
		.map(x => Number(x.LopID))
		.find(x => Number.isInteger(x) && x > 0) || null
}
function taoDangKyTheoLopThanhPhan(dsChon) {
	const map = new Map()
	for (const hs of dsChon) {
		const sources = hs.DSLopNguon || []
		if (!sources.length) {
			showModuleSnackbarDKLT(`Không xác định được LopID nguồn của học sinh "${hs.HoTen}"`, 'warning')
			return null
		}
		for (const lop of sources) {
			const lopID = Number(lop.LopID)
			if (!Number.isInteger(lopID) || lopID <= 0) {
				showModuleSnackbarDKLT(`Lớp "${lop.TenLop || ''}" không có LopID số để lưu`, 'warning')
				return null
			}
			if (!map.has(lopID)) {
				map.set(lopID, {
					LopID: lopID,
					TenLop: lop.TenLop,
					KhoiID: lop.KhoiID,
					MonHocID: lop.MonHocID,
					TenMonHoc: lop.TenMonHoc,
					HocSinh: []
				})
			}
			map.get(lopID).HocSinh.push({
				HocSinhID: hs.HocSinhID,
				HoTen: hs.HoTen,
				LoaiThietBi: hs.ThietBiChon.join(','),
				GhiChu: hs.GhiChu || ''
			})
		}
	}
	return Array.from(map.values()).map(item => Object.assign({}, item, {
		JsonHocSinh: item.HocSinh,
		HocSinh: undefined
	}))
}
async function taiDSDangKyTheoTuan() {
	if (!vueData.TuanXemTKB?.TuanHocID) return []
	// GVCN cần nhìn cả lượt đăng ký của mình và lượt đăng ký thuộc lớp chủ
	// nhiệm; GVBM thuần túy vẫn giữ nguyên phạm vi GVBM như trước.
	const viewModes = coLopChuNhiem() ? ['GVBM', 'GVCN'] : ['GVBM']
	const results = await Promise.allSettled(viewModes.map(viewMode => fetchPromise('lms/DangKyMangLaptop_Get', {
		NienKhoa: vueData.NienKhoa,
		TuanHocID: vueData.TuanXemTKB.TuanHocID,
		LopID: 0,
		KhoiID: 0,
		ViewMode: viewMode
	}, { cache: false })))
	const seen = new Set()
	return results.flatMap(result => result.status === 'fulfilled' ? (result.value || []) : []).filter(item => {
		const key = item.DangKyID || [item.LopID, item.NgayApDung, item.Buoi, item.TietBatDau, item.TietKetThuc, item.TenLop].join('|')
		if (seen.has(key)) return false
		seen.add(key)
		return true
	})
}
async function onSubmitDangKy() {
	if (!vueData.LopItem?.LopID) {
		showModuleSnackbarDKLT('Vui lòng chọn lớp', 'warning')
		return
	}
	const lopIDDangKy = vueData.LopItem.IsLopGop ? null : getLopIDDangKy()
	if (!vueData.LopItem.IsLopGop && !lopIDDangKy) {
		showModuleSnackbarDKLT('Không xác định được lớp gốc để lưu đăng ký lớp nhóm', 'warning')
		return
	}
	if (!vueData.NgayApDung) {
		showModuleSnackbarDKLT('Vui lòng chọn ngày áp dụng', 'warning')
		return
	}
	const dsChon = (vueData.HocSinhThietBi || []).filter(x => x.IsChon)
	if (!dsChon.length) {
		showModuleSnackbarDKLT('Vui lòng chọn ít nhất 1 học sinh', 'warning')
		return
	}
	const chuaChonThietBi = dsChon.find(x => !x.ThietBiChon || !x.ThietBiChon.length)
	if (chuaChonThietBi) {
		showModuleSnackbarDKLT(`Học sinh "${chuaChonThietBi.HoTen}" chưa chọn thiết bị nào`, 'warning')
		return
	}
	if (Number(vueData.TietKetThuc) < Number(vueData.TietBatDau)) {
		showModuleSnackbarDKLT('Tiết kết thúc phải >= tiết bắt đầu', 'warning')
		return
	}
	vueData.isLoadingSave = true
	try {
		const thu = getThu(vueData.NgayApDung)
		const isTreHan = canhBaoTreHan()
		const jsonHocSinh = dsChon.map(x => ({
			HocSinhID: x.HocSinhID,
			HoTen: x.HoTen,
			LoaiThietBi: x.ThietBiChon.join(','),
			GhiChu: x.GhiChu || ''
		}))
		if (vueData.LopItem.IsLopGop) {
			const dsDangKy = taoDangKyTheoLopThanhPhan(dsChon)
			if (!dsDangKy) return false
			await fetchPromise('lms/DangKyMangLaptop_Ins_NhieuLop_JSON', {
				Thu: thu, Buoi: Number(vueData.Buoi), TietBatDau: Number(vueData.TietBatDau),
				TietKetThuc: Number(vueData.TietKetThuc), NgayApDung: vueData.NgayApDung,
				TuanHocID: 0, NienKhoa: vueData.NienKhoa, HocKy: vueData.Semester?.value || 1,
				GhiChu: vueData.GhiChu || '', IsTreHan: isTreHan,
				TenGiaoVienDangKy: vueData.user?.HoTen || vueData.user?.UserName || '',
				JsonDangKy: JSON.stringify(dsDangKy)
			}, { cache: false })
		} else {
			await fetchPromise('lms/DangKyMangLaptop_Ins_JSON', {
				LopID: lopIDDangKy, TenLop: vueData.LopItem.TenLop, KhoiID: vueData.LopItem.KhoiID,
				MonHocID: vueData.LopItem.MonHocID, TenMonHoc: vueData.LopItem.TenMonHoc,
				Thu: thu, Buoi: Number(vueData.Buoi), TietBatDau: Number(vueData.TietBatDau),
				TietKetThuc: Number(vueData.TietKetThuc), NgayApDung: vueData.NgayApDung,
				TuanHocID: 0, NienKhoa: vueData.NienKhoa, HocKy: vueData.Semester?.value || 1,
				GhiChu: vueData.GhiChu || '', IsTreHan: isTreHan,
				JsonHocSinh: JSON.stringify(jsonHocSinh),
				TenGiaoVienDangKy: vueData.user?.HoTen || vueData.user?.UserName || ''
			}, { cache: false })
		}
		showModuleSnackbarDKLT('Đăng ký thành công' + (isTreHan ? ' (đã trễ hạn quy định)' : ''), 'success')
		vueData.TKBQueue = []
		vueData.TKBKeyDangChon = null
		initHocSinhThietBi()
		vueData.GhiChu = ''
		vueData.NgayApDung = null
		vueData.DSDangKy = await taiDSDangKyTheoTuan()
		renderDSDangKy()
		return true
	} catch (error) {
		const errorText = String(error?.message || error || '')
		if (/trùng buổi|đã có đăng ký trùng|đã đăng ký trùng/i.test(errorText)) danhDauTietBiTrungLich()
		return false
	} finally {
		vueData.isLoadingSave = false
	}
}
vueData.renderDSLop = renderDSLop
vueData.renderDSDangKy = renderDSDangKy
vueData.canhBaoTreHan = canhBaoTreHan
vueData.onSubmitDangKy = onSubmitDangKy
vueData.submitDangKy = onSubmitDangKy
vueData.getLopIDDangKy = getLopIDDangKy
vueData.initHocSinhThietBi = initHocSinhThietBi
vueData.toggleThietBi = toggleThietBi
vueData.chonTuanTKBHienTai = chonTuanTKBHienTai
vueData.tinhNgayDauTuanTKB = tinhNgayDauTuanTKB
vueData.renderTKB = renderTKB
vueData.taiDSDangKyTheoTuan = taiDSDangKyTheoTuan
vueData.isTietGVCNDaDangKy = isTietGVCNDaDangKy
vueData.onChonTietTKB = onChonTietTKB
vueData.boChonTietTKB = boChonTietTKB
vueData.dienFormTuTiet = dienFormTuTiet
vueData.isTietDaChon = isTietDaChon
vueData.chonTatCaHocSinh = chonTatCaHocSinh
vueData.boChonTatCaHocSinh = boChonTatCaHocSinh
vueData.toggleChonHocSinh = toggleChonHocSinh
vueData.isCotThietBiChonHet = isCotThietBiChonHet
vueData.toggleCotThietBi = toggleCotThietBi