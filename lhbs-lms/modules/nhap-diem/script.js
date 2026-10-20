/**
 * BangDiemService.js
 * Service xử lý nghiệp vụ bảng điểm
 * Version: 1.1.0
 */
// ==================== CONSTANTS ====================
const CONSTANTS = {
    SUBJECT_IDS: {
        ENGLISH_5: 5,
        ENGLISH_46: 46,
        ENGLISH_76: 76,
        STEM_36: 36,
        GROUP_101: 101
    },
    ENGLISH_SUBJECTS: [5, 46, 76],
    GROUP_SUBJECTS: [101, 76],
    CONVERT_STAR_SUBJECTS: [36, 37, 38, 40, 41, 42, 43, 106],
    COLUMN_TYPES: {
        NUMBER: 'number',
        TEXT: 'text',
        ICO_STAR: 'ICO_Star',
        DROPDOWN_TEXT: 'Dropdown_text',
        DROPDOWN_THC: 'Dropdown_THC',
        DROPDOWN_TDC: 'Dropdown_TDC',
        DROPDOWN_CD_D: 'Dropdown_CD_D'
    },
    FORMULA_COLUMN: 'Công thức',
    CENTER_ALIGN_COLUMNS: [
        'MucDoDanhGia', 'DiemGK_HK2', 'DiemGK_HK1', 'DiemCK_HK1',
        'Theme1_Result', 'Theme2_Result', 'Theme3_Result', 'Theme4_Result',
        'Theme5_Result', 'Theme6_Result', 'Theme7_Result', 'Theme8_Result'
    ],
    THEME_MAPPING: {
        'Theme_2': { nhom: 'S1_Mid_TA2', cot: 'S1_Mid_TA2_Point', target: 'Theme2_TST' },
        'Theme_4': { nhom: 'S1_Final_TA2', cot: 'S1_Final_TA2_Point', target: 'Theme4_TST' },
        'Theme_6': { nhom: 'S2_Mid_TA2', cot: 'S2_Mid_TA2_Point', target: 'Theme6_TST' },
        'Theme_8': { nhom: 'S2_Final_TA2', cot: 'S2_Final_TA2_Point', target: 'Theme8_TST' }
    },
    TINH_TRANG: {
        LUU_TAM: 1,
        GUI_BGH: 2,
        TU_CHOI_GVCN: 3,
        DUYET_GVCN: 4,
        TU_CHOI_TO_TRUONG: 5,
        DUYET_TO_TRUONG: 6,
        TU_CHOI_BGH: 7,
        DUYET_BGH: 8
    },
};
// ==================== COLUMN CODE SERVICE ====================
const ColumnCodeService = {
    hasNumericPrefix(maCotDiem) {
        if (typeof maCotDiem !== 'string') return false;
        const splitIndex = maCotDiem.indexOf('_');
        if (splitIndex <= 0) return false;
        const prefix = maCotDiem.slice(0, splitIndex);
        return /^\d+$/.test(prefix);
    },
    /** Chuẩn hóa mã cột điểm: 13083_MucDoDanhGiaCK_HK2 -> MucDoDanhGiaCK_HK2 */
    normalizeMaCotDiem(maCotDiem) {
        if (typeof maCotDiem !== 'string') return maCotDiem;
        const splitIndex = maCotDiem.indexOf('_');
        if (splitIndex <= 0) return maCotDiem;
        const prefix = maCotDiem.slice(0, splitIndex);
        return /^\d+$/.test(prefix) ? maCotDiem.slice(splitIndex + 1) : maCotDiem;
    },
    /** So khớp mã cột điểm giữa API và UI, hỗ trợ cả dạng có prefix CotDiemID */
    isSameMaCotDiem(leftCode, rightCode) {
        const leftHasPrefix = this.hasNumericPrefix(leftCode);
        const rightHasPrefix = this.hasNumericPrefix(rightCode);
        // NLPC columns (prefixed) must match by exact code, not normalized main-subject code.
        if (leftHasPrefix || rightHasPrefix) {
            if (leftHasPrefix !== rightHasPrefix) return false;
            return leftCode === rightCode;
        }
        return this.normalizeMaCotDiem(leftCode) === this.normalizeMaCotDiem(rightCode);
    }
};
// ==================== API SERVICE ====================
const ApiService = {
    /** Gọi API lấy dữ liệu bảng điểm */
    async fetchBangDiem(action, params) {
        return await ajaxCALLPromise(action, params);
    },
    /** Lấy lịch sử thay đổi điểm của cả lớp hoặc riêng một học sinh nếu truyền HocSinhID */
    async getLogDiem(params) {
        return await ajaxCALLPromise("lms/Log_Diem", params);
    },
    /** Lấy danh mục giáo viên để đổi mã người nhập trong lịch sử thành họ tên dễ đọc. */
    async getTeacherList() {
        return await ajaxCALLPromise("lms/GiaoVien_Get");
    },
    /** Lưu dữ liệu điểm */
    async saveGradeData(params) {
        return await ajaxCALLPromise("lms/KQHT_MonHocLop_Ins", params);
    },
    /** Cập nhật tình trạng Cấp 1 */
    async updateTinhTrang(params) {
        return await ajaxCALLPromise("lms/KQHT_MonHocLop_TinhTrang_Udp", {
            ...params,
            IsSendToManager: true
        });
    },
    /** Cập nhật tình trạng Cấp 1 - Lưu tạm */
    async updateTinhTrangLuuTam(params) {
        return await ajaxCALLPromise("lms/KQHT_MonHocLop_TinhTrang_Udp", {
            ...params,
            IsSendToManager: false
        });
    },
    /** Lấy MonHocLop theo MonHocID */
    async getMonHocLopByMonHocID(params) {
        return await ajaxCALLPromise("lms/MonHocLop_Select_By_MonHocID", params);
    },
    /** Cập nhật tình trạng Cấp 2, Cấp 3 */
    async updateTinhTrangC2C3(params) {
        return await ajaxCALLPromise("lms/KQHT_MonHocLop_TinhTrang_Udp_C2_C3", params);
    },
    /** Lấy danh sách khóa cột điểm */
    async getKhoaCotDiem(params) {
        return await ajaxCALLPromise("lms/KhoaCotDiem_Get", params);
    },
    /** Khóa/Mở khóa cột điểm */
    async toggleKhoaCotDiem(params) {
        return await ajaxCALLPromise("lms/KhoaCotDiem_Ins_And_Upd", params);
    },
    // Giữ helper gọi mark/lms_syncdiem ở comment trong lúc kiểm tra payload.
//     /** Đẩy dữ liệu điểm LMS sang QLDiem sau khi khóa cột điểm. */
//     async syncDiemToQLDiem(params) {
//         return await ajaxCALLPromise("mark/lms_syncdiem", params);
//     },
    /** Cập nhật tình trạng khóa cột điểm theo KhoaCotDiemID */
    async updateKhoaCotDiemTinhTrang(params) {
        return await ajaxCALLPromise("lms/KhoaCotDiem_TinhTrang_Upd_ByKhoaCotDiem", params);
    },
    /** Lấy config STEM theo niên khóa từ tblConfig_STEM */
    async getSTEMConfig(params) {
        return await ajaxCALLPromise("lms/Config_STEM_Get", params);
    },
};
// STEM thay đổi cấu trúc theo từng niên khóa. Chỉ coi là luồng legacy khi
// server thực sự trả về cấu hình Config_STEM đang bật cho niên khóa/khối đó;
// thiếu cấu hình phải rơi về luồng template chuẩn, tránh dùng nhầm logic năm cũ.
const StemModeService = {
    normalizeConfigList(response) {
        if (Array.isArray(response)) return response;
        if (Array.isArray(response?.Result)) return response.Result;
        return [];
    },
    isEnabled(value) {
        return value === true || value === 1 || String(value ?? '').trim() === '1';
    },
    hasLegacyConfig(configList) {
        return this.normalizeConfigList(configList).some(config => this.isEnabled(config?.Enable));
    },
    getConfigForSemester(configList, semester) {
        return this.normalizeConfigList(configList).find(config =>
            config?.HocKi === semester && this.isEnabled(config?.Enable)
        );
    }
};
// ==================== FILTER SERVICE ====================
const FilterService = {
    /** Xác định action API dựa trên filter */
    getBangDiemAction(filter, vueData, stemConfigList = []) {
        const monHocID = filter.MonHocItem?.MonHocID;
        const maNhom = filter.MaNhomCotDiemItem?.MaNhomCotDiem;
        const hocKi = filter.MaNhomCotDiemItem?.Semester;
        // Môn 5 (English) - DiemCK/DiemGK
        if (monHocID === 5 && (maNhom?.includes('DiemCK') || maNhom?.includes('DiemGK'))) {
            return 'lms/HocSinhBangDiem_Get_ByThuTuNhom';
        }
        // Môn 36 (STEM): chỉ dùng endpoint legacy khi niên khóa có Config_STEM.
        // STEM không có cấu hình (ví dụ template mới) dùng endpoint theo template như AI.
        if (monHocID === CONSTANTS.SUBJECT_IDS.STEM_36 && StemModeService.hasLegacyConfig(stemConfigList)) {
            const stemConfig = StemModeService.getConfigForSemester(stemConfigList, hocKi);
            if (!stemConfig || maNhom?.includes(stemConfig.HocKi_LayTongDiemChuDe)) {
                if (maNhom?.includes('DiemCK') || maNhom?.includes('DiemGK')) {
                    return 'lms/HocSinhBangDiem_STEM_CK_Get';
                }
            }
        }
        return 'lms/HocSinhBangDiem_Get_ByMonHocID_MaNhom';
    },
    /** Kiểm tra môn học có phải Tiếng Anh */
    isEnglishSubject(monHocID) {
        return CONSTANTS.ENGLISH_SUBJECTS.includes(monHocID);
    },
    /** Kiểm tra môn học có phải môn nhóm */
    isGroupSubject(monHocID) {
        return CONSTANTS.GROUP_SUBJECTS.includes(monHocID);
    },
    /** Kiểm tra môn học có đổi sao */
    isMonHocConvertWithStar(monHocID) {
        return CONSTANTS.CONVERT_STAR_SUBJECTS.includes(monHocID);
    },
    /** Kiểm tra filter hợp lệ */
    isValidFilter(filter) {
        return filter.KhoiItem !== null &&
            filter.LopItem !== null &&
            filter.MonHocItem !== null &&
            filter.MaNhomCotDiemItem !== null;
    }
};
// ==================== DATA PROCESSOR ====================
const DataProcessor = {
    /** Xử lý danh sách học sinh duy nhất */
    processStudentList(apiData) {
        const uniqueIds = [...new Set(apiData.map(x => x.HocSinhID))];
        return uniqueIds.map(id => {
            const student = apiData.find(y => y.HocSinhID === id);
            return {
                Ho: student.Ho,
                HocSinhID: student.HocSinhID,
                NgaySinh: student.NgaySinh,
                Nu: student.Nu,
                SoDanhBo: student.SoDanhBo,
                Ten: student.Ten,
                TinhTrang: student.TinhTrang,
            };
        });
    },
    /** Tính số cột freeze dựa trên môn học */
    calculateFreezeColumns(monHocID, isEnglish, isGroup) {
        if (monHocID === CONSTANTS.SUBJECT_IDS.ENGLISH_5 ||
            monHocID === CONSTANTS.SUBJECT_IDS.ENGLISH_46) {
            return isEnglish ? 4 : 3;
        }
        if (monHocID === CONSTANTS.SUBJECT_IDS.ENGLISH_76) {
            return isEnglish ? 5 : 3;
        }
        if (monHocID === CONSTANTS.SUBJECT_IDS.GROUP_101) {
            return 4;
        }
        return 3;
    },
    /** Xử lý giá trị cột không có công thức */
    processNonFormulaValue(column) {
        const { GiaTriCotDiem, KetQuaDanhGia_VI, MaCotDiem, KQHTID } = column;
        if (GiaTriCotDiem === CONSTANTS.COLUMN_TYPES.NUMBER) {
            return (KetQuaDanhGia_VI === '' || KetQuaDanhGia_VI === null)
                ? null
                : parseFloat(KetQuaDanhGia_VI);
        }
        let value = KetQuaDanhGia_VI;
        if (MaCotDiem.includes('MucDoDanhGia') && KQHTID === 0) {
            value = value || 'T';
        }
        return value;
    },
    /** Validate dữ liệu trước khi lưu */
    validateSave(typeCell, value, min, max) {
        if (value == null || value === '') return 0;
        if (typeCell === 'number' && (value < min || value > max)) return 1;
        return 0;
    },
    /**
     * Kiểm tra các cột chưa khóa mà tất cả học sinh đã nhập đủ điểm
     * @returns {Array} Danh sách cột { value, title } đủ điều kiện gợi ý khóa
     */
    getColumnsReadyToLock(DSHocSinh, DSCotDiem_ByMaNhomCotDiem, displayColumns, apiData) {
        if (!DSHocSinh?.length || !DSCotDiem_ByMaNhomCotDiem?.length) return [];
        return DSCotDiem_ByMaNhomCotDiem.filter(cotDiem => {
            const display = displayColumns.find(d => d.value === cotDiem.value);
            if (display?.isLocked) return false;
            const apiColumn = apiData?.find(x => x.MaCotDiem === cotDiem.value);
            if (apiColumn?.QuyenNhapDiem === false || apiColumn?.QuyenNhapDiem === 0) return false;
            const formula = cotDiem.Formula ?? apiColumn?.Formula;
            const isFormula = DataProcessor.isFormulaColumn(cotDiem, apiColumn);
            if (isFormula) {
                // Không dùng giá trị tự tính của formula để xác định đã nhập.
                // Formula chỉ hoàn tất khi ít nhất một cột đầu vào của nó có
                // dữ liệu trên từng học sinh (default cũng được tính là dữ liệu).
                if (!formula) return false;
                const inputColumns = DSCotDiem_ByMaNhomCotDiem.filter(input => {
                    const col = apiData?.find(x => x.MaCotDiem === input.value);
                    if (col?.QuyenNhapDiem === false || col?.QuyenNhapDiem === 0) return false;
                    return !DataProcessor.isFormulaColumn(input, col) &&
                        new RegExp(`\\b${DataProcessor.escapeRegExp(input.value)}\\b`).test(formula);
                });
                if (!inputColumns.length) return false;
                return DSHocSinh.every(hs => inputColumns.some(input =>
                    hs[input.value] !== null && hs[input.value] !== undefined && hs[input.value] !== ''
                ));
            }
            return DSHocSinh.every(hs => {
                const val = hs[cotDiem.value];
                return val !== null && val !== undefined && val !== '';
            });
        });
    },
    isFormulaColumn(column, apiColumn) {
        const type = String(column?.LoaiCotDiem ?? apiColumn?.LoaiCotDiem ?? '').trim().toLowerCase();
        return type === CONSTANTS.FORMULA_COLUMN.toLowerCase() || Boolean(column?.Formula ?? apiColumn?.Formula);
    },
    escapeRegExp(value) {
        return String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    },
    /** Xử lý dữ liệu trước khi push API */
    processBeforePushAPI(editedCells, DSHocSinh, DSHocSinh_API, freezeColumns, filter, instance) {
        console.log(
            "editedCells", editedCells,
            "\nDSHocSinh", DSHocSinh,
            "\nDSHocSinh_API", DSHocSinh_API,
            "\nfreezeColumns", freezeColumns,
            "\nfilter", filter,
            "\ninstance", instance
        );
        const dataBeforeInsertToDB = [];
        const sheet = Array.isArray(instance) ? instance[0] : instance;
        const firstStudentId = DSHocSinh[0]?.HocSinhID;
        const gradeColumns = DSHocSinh_API.filter(column =>
            String(column.HocSinhID) === String(firstStudentId)
        );
        const manualEdits = editedCells.filter(cell => !cell.formulaMismatch);
        const formulaMismatchByStudent = new Map();
        editedCells.filter(cell => cell.formulaMismatch && cell.studentId != null && cell.columnCode)
            .forEach(cell => {
                const studentId = String(cell.studentId);
                if (!formulaMismatchByStudent.has(studentId)) formulaMismatchByStudent.set(studentId, new Map());
                formulaMismatchByStudent.get(studentId).set(String(cell.columnCode), cell);
            });
        const editedRows = new Set(manualEdits.map(cell => Number(cell.y)));
        for (let i = 0; i < DSHocSinh.length; i++) {
            const hocSinh = DSHocSinh[i];
            const hasManualEdits = editedRows.has(i);
            const rowFormulaMismatches = formulaMismatchByStudent.get(String(hocSinh.HocSinhID));
            if (!hasManualEdits && !rowFormulaMismatches?.size) continue;
            for (let currentJ = 0; currentJ < gradeColumns.length; currentJ++) {
                const cellX = currentJ + freezeColumns;
                const exists = hasManualEdits && manualEdits.find(cell => Number(cell.x) === cellX && Number(cell.y) === i);
                const cotDiem = gradeColumns[currentJ];
                const isFormulaColumn = this.isFormulaColumn(cotDiem);
                const formulaMismatch = rowFormulaMismatches?.get(String(cotDiem.MaCotDiem));
                // Cột công thức chỉ được tính ở trình duyệt; API lưu không tự tính lại.
                // Khi lưu một ô công thức lệch, gửi giá trị vừa tính của đúng học sinh/cột dù không có ô nhập tay nào đổi.
                if (hasManualEdits) {
                    if (!exists && !isFormulaColumn) continue;
                } else if (!isFormulaColumn || !formulaMismatch) {
                    continue;
                }
                let giaTriCotDiem = hocSinh[cotDiem.MaCotDiem];
                if (isFormulaColumn) {
                    if (formulaMismatch) {
                        giaTriCotDiem = formulaMismatch.value;
                    } else {
                        const formulaCell = sheet?.records?.[i]?.[cellX]?.element;
                        const renderedValue = formulaCell?.textContent;
                        giaTriCotDiem = renderedValue == null
                            ? formulaCell?.innerHTML
                            : renderedValue.trim();
                        giaTriCotDiem = giaTriCotDiem == null ? '' : giaTriCotDiem;
                    }
                    if (cotDiem.GiaTriCotDiem === CONSTANTS.COLUMN_TYPES.NUMBER && giaTriCotDiem !== '') {
                        const numericValue = Number(giaTriCotDiem);
                        const isFormulaError = /^#(REF!?|DIV\/0!?|VALUE!?|NAME\?|N\/A|NUM!?|NULL!?|ERROR!?)/i.test(String(giaTriCotDiem).trim());
                        if (!Number.isFinite(numericValue) || isFormulaError) {
                            const cellAddress = jspreadsheet.helpers.getCellNameFromCoords(cellX, i);
                            sheet?.setStyle(cellAddress, 'background-color', 'red');
                            Vue.$toast.error(
                                `Công thức cột ${cotDiem.MaCotDiem} chưa cho ra giá trị hợp lệ, vui lòng kiểm tra dữ liệu đầu vào!`,
                                { position: 'top' }
                            );
                            return undefined;
                        }
                        giaTriCotDiem = numericValue;
                    }
                }
                if (cotDiem.GiaTriCotDiem === 'number') {
                    if (giaTriCotDiem === null || giaTriCotDiem === NaN || giaTriCotDiem === '') {
                        giaTriCotDiem = '';
                    }
                }
                const cotDiem_HS = {
                    HocSinhID: hocSinh.HocSinhID,
                    LopID: filter.LopItem.LopID,
                    NienKhoa: filter.NienKhoa,
                    CotDiemID: cotDiem.CotDiemID,
                    KetQuaDanhGia_VI: giaTriCotDiem,
                    KetQuaDanhGia_EN: giaTriCotDiem,
                    KQHTID: DSHocSinh_API.find(x =>
                        x.HocSinhID === hocSinh.HocSinhID &&
                        x.MaCotDiem === cotDiem.MaCotDiem
                    )?.KQHTID ?? 0,
                    KhoaCotDiemID: DSHocSinh_API.find(x =>
                        x.HocSinhID === hocSinh.HocSinhID &&
                        x.MaCotDiem === cotDiem.MaCotDiem
                    )?.KhoaCotDiemID ?? 0,
                };
                cotDiem_HS.IsError = this.validateSave(
                    cotDiem.GiaTriCotDiem,
                    cotDiem_HS.KetQuaDanhGia_VI,
                    cotDiem.DiemMin,
                    cotDiem.DiemMax
                );
                if (cotDiem_HS.IsError === 1) {
                    const cellAddress = jspreadsheet.helpers.getCellNameFromCoords(cellX, i);
                    sheet?.setStyle(cellAddress, 'background-color', 'red');
                    Vue.$toast.error(
                        `Cột điểm ${cotDiem.MaCotDiem} chỉ cho phép nhập thang điểm từ ${cotDiem.DiemMin} đến ${cotDiem.DiemMax}!`,
                        { position: 'top' }
                    );
                    return undefined;
                }
                cotDiem_HS.KetQuaDanhGia_VI = cotDiem_HS.KetQuaDanhGia_VI === NaN
                    ? null
                    : cotDiem_HS.KetQuaDanhGia_VI;
                dataBeforeInsertToDB.push(cotDiem_HS);
            }
        }
        return dataBeforeInsertToDB.filter(x =>
            (x.KQHTID && x.KQHTID > 0) ||
            (x.KetQuaDanhGia_VI != null && x.KetQuaDanhGia_VI !== '' && !Number.isNaN(x.KetQuaDanhGia_VI))
        ).filter(x => !Number.isNaN(x.KetQuaDanhGia_VI));
    }
};
// ==================== HEADER BUILDER ====================
const HeaderBuilder = {
    /** Build cột thông tin học sinh */
    buildStudentInfoColumns(isGroup, isEnglish) {
        const isLanguage = JSON.parse(localStorage.getItem('IsLanguage')) ?? false;
        const columns = [
            {
                type: 'text', title: isLanguage ? 'Student ID' : 'Mã học sinh', name: 'HocSinhID',
                width: 100, backGroundColor: null, wrap: true, readOnly: true
            },
            {
                type: 'text', title: isLanguage ? 'Student Book No.' : 'Số Danh Bộ', name: 'SoDanhBo',
                width: 100, backGroundColor: null, wrap: true, readOnly: true
            },
            {
                type: 'text', title: isLanguage ? 'Student Name' : 'Họ tên học sinh', name: 'HoVaTenHocSinh',
                width: 200, backGroundColor: null, wrap: true, align: "left", readOnly: true
            }
        ];
        if (isGroup) {
            columns.push({
                type: 'text', title: isLanguage ? 'Homeroom Class' : 'Lớp chủ nhiệm', name: 'TenLop',
                width: 70, backGroundColor: null, wrap: true, align: "left", readOnly: true
            });
        }
        if (isEnglish || isLanguage) {
            columns.push({
                type: 'text', title: 'English Name', name: 'EnglishName',
                width: 100, backGroundColor: null, wrap: true, align: "left", readOnly: true
            });
        }
        return columns;
    },
    /** Build cột điểm */
    buildGradeColumn(column, isEnglish, isDisabled, lockedColumns) {
        const isLanguage = JSON.parse(localStorage.getItem('IsLanguage')) ?? false;
        const isLocked = lockedColumns.some(x =>
            ColumnCodeService.isSameMaCotDiem(x.MaCotDiem, column.MaCotDiem) && x.TinhTrang
        );
        const isNoPermission = column.QuyenNhapDiem === false || column.QuyenNhapDiem === 0;
        let title = (isLanguage || isEnglish) ? (column.TenHienThi_EN || column.TenHienThi_VI) : column.TenHienThi_VI;
        let backGroundColor = column.HexBackground;
        let width = parseInt(column?.WidthCSS ?? 80);
        if (isLocked) {
            title += isLanguage ? ' (LOCKED)' : ' (KHÓA)';
            backGroundColor = '#c1c1c157';
            width += 25;
        } else if (isNoPermission) {
            backGroundColor = column.HexBackground || '#f5f5f5';
        }
        const isFormulaColumn = column.LoaiCotDiem === CONSTANTS.FORMULA_COLUMN;
        const displayTitle = title;
        let formulaTooltipText = '';
        let formulaTooltipFormula = '';
        if (isFormulaColumn) {
            // Chừa chỗ cho icon thông tin và khoảng cách cạnh tên cột; các cột nhập tay giữ nguyên width.
            width += 24;
            const isEnglishLabel = isLanguage || isEnglish;
            formulaTooltipFormula = column.Formula == null ? '' : String(column.Formula).trim();
            formulaTooltipText = (isEnglishLabel ? 'Formula: ' : 'Công thức: ') +
                (formulaTooltipFormula || (isEnglishLabel ? 'Not configured' : 'Chưa cấu hình'));
        }
        // JExcel hiển thị title như text, nên giữ title thuần và truyền metadata riêng để giao diện chèn icon DOM thật.
        const config = {
            title, displayTitle, name: column.MaCotDiem, width,
            typeValue: column.GiaTriCotDiem,
            type: this.mapValueTypeToJssType(column.GiaTriCotDiem),
            backGroundColor, wrap: true,
            readOnly: isFormulaColumn || isNoPermission || isDisabled || isLocked
        };
        if (isFormulaColumn) {
            config.formulaTooltipText = formulaTooltipText;
        }
        return this.buildColumnByType(column.GiaTriCotDiem, config, column);
    },
    mapValueTypeToJssType(valueType) {
        return valueType === CONSTANTS.COLUMN_TYPES.NUMBER ? 'numeric' : 'text';
    },
    /** Build cấu hình cột theo type */
    buildColumnByType(valueType, baseConfig, columnData) {
        const builders = {
            [CONSTANTS.COLUMN_TYPES.NUMBER]: () => ({
                ...baseConfig, type: 'numeric', decimal: '.', autoWidth: true, align: 'center'
            }),
            [CONSTANTS.COLUMN_TYPES.TEXT]: () => ({
                ...baseConfig, type: 'text',
                align: this.shouldCenterAlign(columnData.MaCotDiem) ? 'center' : 'left'
            }),
            [CONSTANTS.COLUMN_TYPES.ICO_STAR]: () => ({
                ...baseConfig, type: 'html', align: 'center'
            }),
            [CONSTANTS.COLUMN_TYPES.DROPDOWN_TEXT]: () => ({
                ...baseConfig, type: 'dropdown', align: 'center',
                source: [{ id: '1', name: 'Done' }, { id: '0', name: 'Not Yet' }]
            }),
            [CONSTANTS.COLUMN_TYPES.DROPDOWN_THC]: () => ({
                ...baseConfig, type: 'dropdown', align: 'center', source: ['T', 'H', 'C']
            }),
            [CONSTANTS.COLUMN_TYPES.DROPDOWN_TDC]: () => ({
                ...baseConfig, type: 'dropdown', align: 'center', source: ['T', 'Đ', 'C']
            }),
            [CONSTANTS.COLUMN_TYPES.DROPDOWN_CD_D]: () => ({
                ...baseConfig, type: 'dropdown', align: 'center', source: ['CĐ', 'Đ']
            })
        };
        const builder = builders[valueType];
        return builder ? builder() : baseConfig;
    },
    shouldCenterAlign(columnCode) {
        return CONSTANTS.CENTER_ALIGN_COLUMNS.some(col => columnCode.includes(col));
    },
    /** Build nested headers */
    buildNestedHeaders(gradeColumns, apiData, freezeColumns, isGroup) {
        const isLanguage = JSON.parse(localStorage.getItem('IsLanguage')) ?? false;
        const groupNames = [...new Set(apiData.map(x => x.MaNhomCotDiem))];
        const nestedHeader = [{
            title: isLanguage ? 'Student Information' : 'Thông tin học sinh',
            colspan: freezeColumns + (isGroup ? 1 : 0)
        }];
        groupNames.forEach(groupName => {
            const matchingColumn = gradeColumns.find(col => col.MaNhomCotDiem === groupName);
            const columnCount = gradeColumns.filter(col => col.MaNhomCotDiem === groupName).length;
            nestedHeader.push({
                title: isLanguage ? (matchingColumn?.TenNhomCotDiem_EN || matchingColumn?.TenNhomCotDiem_VI) : matchingColumn?.TenNhomCotDiem_VI,
                colspan: columnCount
            });
        });
        return [nestedHeader];
    }
};
// ==================== FORMULA PROCESSOR ====================
const FormulaProcessor = {
    /** Xử lý cột có công thức */
    processFormulaValue(column, allColumns, rowIndex, filter, headers, freezeColumns, isEnglish, vueData, isLegacyStem) {
        const { Formula, GiaTriCotDiem, KetQuaDanhGia_VI, MaCotDiem } = column;
        const groupCode = filter.MaNhomCotDiemItem?.MaNhomCotDiem;
        const columnsCotDiem = headers.filter(h => h.typeValue);
        if (!Formula) {
            return GiaTriCotDiem === CONSTANTS.COLUMN_TYPES.NUMBER
                ? parseFloat(KetQuaDanhGia_VI ?? 0)
                : KetQuaDanhGia_VI;
        }
        if (this.isCase_DiemTBCK(groupCode, MaCotDiem)) return KetQuaDanhGia_VI;
        if (this.isCase_Cap1_DanhHieu(MaCotDiem, vueData)) {
            return '=' + replaceFormula(columnsCotDiem, Formula, rowIndex, freezeColumns);
        }
        if (this.isCase_EnglishThemeResult(column, isEnglish, filter)) return KetQuaDanhGia_VI;
        if (this.isCase_STEM_TongDiem(groupCode, MaCotDiem, filter.MonHocItem?.MonHocID, isLegacyStem)) return KetQuaDanhGia_VI;
        if (this.isCase_STEM_DiemCK(groupCode, MaCotDiem, filter.MonHocItem?.MonHocID, isLegacyStem)) {
            const expandedFormula = this.expandRangeInFormula(Formula, allColumns);
            return '=' + replaceFormula(columnsCotDiem, expandedFormula, rowIndex, freezeColumns);
        }
        if (allColumns.length === 1) return parseFloat(KetQuaDanhGia_VI ?? 0);
        if (GiaTriCotDiem === CONSTANTS.COLUMN_TYPES.ICO_STAR) return parseFloat(KetQuaDanhGia_VI ?? 0);
        if ([CONSTANTS.COLUMN_TYPES.NUMBER, CONSTANTS.COLUMN_TYPES.TEXT].includes(GiaTriCotDiem)) {
            return '=' + replaceFormula(columnsCotDiem, Formula, rowIndex, freezeColumns);
        }
        return KetQuaDanhGia_VI;
    },
    isCase_DiemTBCK(groupCode, maCotDiem) {
        return ['DiemTBGK_HK1', 'DiemTBGK_HK2', 'DiemTBCK_HK1', 'DiemTBCK_HK2'].includes(groupCode) &&
            !['DiemTBGK_HK1', 'DiemTBCK_HK2', 'DiemTBCK_HK1', 'DiemTBCK_HK2'].includes(maCotDiem) &&
            !maCotDiem.includes('DanhHieu');
    },
    isCase_Cap1_DanhHieu(maCotDiem, vueData) {
        return vueData.CapID === 1 && [
            'DiemTBGK_HK1', 'DiemTBCK_HK1', 'DiemTBGK_HK2', 'DiemTBCK_HK2',
            'DanhHieuGK_HK1', 'DanhHieuCK_HK1', 'DanhHieuGK_HK2', 'DanhHieuCK_HK2'
        ].includes(maCotDiem);
    },
    isCase_EnglishThemeResult(column, isEnglish, filter) {
        return isEnglish && this.isGetResultTopic(column, filter);
    },
    isCase_STEM_TongDiem(groupCode, maCotDiem, monHocID, isLegacyStem) {
        return isLegacyStem &&
            (groupCode?.includes('DiemCK') || groupCode?.includes('DiemGK')) &&
            monHocID === CONSTANTS.SUBJECT_IDS.STEM_36 &&
            ['TongDiem_CD1', 'TongDiem_CD2', 'TongDiem_CD3'].some(x => maCotDiem.includes(x));
    },
    isCase_STEM_DiemCK(groupCode, maCotDiem, monHocID, isLegacyStem) {
        return isLegacyStem &&
            (groupCode?.includes('DiemCK') || groupCode?.includes('DiemGK')) &&
            monHocID === CONSTANTS.SUBJECT_IDS.STEM_36 &&
            ['DiemCK_', 'DiemGK_', 'SaoCK_', 'SaoGK_'].some(x => maCotDiem.includes(x));
    },
    /** Expand range "ColA:ColB" → "ColA, ColB, ColC, ..." */
    expandRangeInFormula(formula, allColumns) {
        return formula.replace(/(\w+):(\w+)/g, (match, startCol, endCol) => {
            const colNames = allColumns.map(c => c.MaCotDiem);
            const startIdx = colNames.indexOf(startCol);
            const endIdx = colNames.indexOf(endCol);
            if (startIdx === -1 || endIdx === -1 || startIdx > endIdx) return match;
            return colNames.slice(startIdx, endIdx + 1).join(', ');
        });
    },
    isGetResultTopic(column, filter) {
        const groupCode = filter.MaNhomCotDiemItem?.MaNhomCotDiem;
        const { MaCotDiem } = column;
        const isInGradeGroup = groupCode?.includes('DiemGK_') || groupCode?.includes('DiemCK_');
        const isNotMainColumn = !MaCotDiem.includes('DiemGK_') && !MaCotDiem.includes('DiemCK_') &&
            !MaCotDiem.includes('DiemTBGK_') && !MaCotDiem.includes('DiemTBCK_');
        return isInGradeGroup && isNotMainColumn;
    }
};
// ==================== STYLE SERVICE ====================
const StyleService = {
    /** Áp dụng background style */
    applyBackgroundStyles(students, gradeColumns, freezeColumns) {
        const styleSheet = {};
        students.forEach((row, rowIndex) => {
            gradeColumns.forEach((column, colIndex) => {
                const cellAddress = jspreadsheet.helpers.getCellNameFromCoords(
                    colIndex + freezeColumns, rowIndex
                );
                if (column.HexBackground) {
                    styleSheet[cellAddress] = `background-color: ${column.HexBackground}`;
                }
                const isNoPermission = column.QuyenNhapDiem === false || column.QuyenNhapDiem === 0;
                const value = row[column.MaCotDiem];
                if ((value === null || value === '') && !isNoPermission && column.LoaiCotDiem !== CONSTANTS.FORMULA_COLUMN) {
                    styleSheet[cellAddress] = 'background-color: #ffff0052';
                }
            });
        });
        return styleSheet;
    },
    /** Áp dụng comments */
    applyComments(students, gradeColumns, apiData, freezeColumns) {
        const comments = {};
        // Build lookup map O(n) thay vì find() O(n) trong double loop
        const commentMap = {};
        apiData.forEach(x => {
            if (x.Is_Comment) {
                commentMap[`${x.HocSinhID}_${x.MaCotDiem}`] = x.NhapDiemUser;
            }
        });
        students.forEach((row, rowIndex) => {
            gradeColumns.forEach((column, colIndex) => {
                const user = commentMap[`${row.HocSinhID}_${column.MaCotDiem}`];
                if (user) {
                    const cellAddress = jspreadsheet.helpers.getCellNameFromCoords(
                        colIndex + freezeColumns, rowIndex
                    );
                    comments[cellAddress] = `Cột điểm do ${user} đã nhập`;
                }
            });
        });
        return comments;
    }
};
// ==================== EXPORT SERVICE ====================
const ExportService = {
    /** Export Excel */
    exportExcel(headers, data, fileName) {
        const headerNames = headers.map(x => x.name);
        const exportData = data.map(item => headerNames.map(h => item[h] ?? ""));
        const worksheet = XLSX.utils.aoa_to_sheet([headerNames, ...exportData]);
        const workbook = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(workbook, worksheet, 'Sheet1');
        XLSX.writeFile(workbook, fileName);
    },
    /** Export workbook nhiều sheet */
    exportWorkbook(sheets, fileName) {
        const workbook = XLSX.utils.book_new();
        const usedSheetNames = new Set();
        sheets.forEach((sheet, index) => {
            const headerNames = sheet.headers.map(x => x.name);
            const exportData = sheet.data.map(item => headerNames.map(h => item[h] ?? ""));
            const worksheet = XLSX.utils.aoa_to_sheet([headerNames, ...exportData]);
            XLSX.utils.book_append_sheet(
                workbook,
                worksheet,
                this.normalizeSheetName(sheet.name || `Sheet${index + 1}`, usedSheetNames)
            );
        });
        XLSX.writeFile(workbook, this.normalizeFileName(fileName));
    },
    normalizeSheetName(name, usedSheetNames = new Set()) {
        const baseName = String(name || 'Sheet')
            .replace(/[\\/?*[\]:]/g, ' ')
            .trim()
            .slice(0, 31);
        let safeName = baseName || 'Sheet';
        let count = 1;
        while (usedSheetNames.has(safeName)) {
            const suffix = `_${count}`;
            safeName = `${(baseName || 'Sheet').slice(0, 31 - suffix.length)}${suffix}`;
            count++;
        }
        usedSheetNames.add(safeName);
        return safeName;
    },
    normalizeFileName(fileName) {
        return String(fileName || 'Bang_Diem.xlsx')
            .replace(/[\\/:*?"<>|]/g, '_')
            .replace(/\s+/g, '_');
    },
    prepareExportData(DSHocSinh, DSCotDiem_ByMaNhomCotDiem, instance, freezeColumns, filter, apiData = []) {
        const dataExcel = [];
        const isEnglish = FilterService.isEnglishSubject(filter.MonHocItem?.MonHocID);
        const isGroup76 = filter.MonHocItem?.MonHocID === 76;
        for (let i = 0; i < DSHocSinh.length; i++) {
            const cotDiem_HS = {
                HocSinhID: DSHocSinh[i].HocSinhID,
                HoVaTenHocSinh: DSHocSinh[i].HoVaTenHocSinh,
                SoDanhBo: DSHocSinh[i].SoDanhBo
            };
            if (isGroup76) cotDiem_HS.TenLop = DSHocSinh[i].TenLop ?? '';
            if (isEnglish) cotDiem_HS.EnglishName = DSHocSinh[i].EnglishName ?? '';
            for (let j = 0; j < DSCotDiem_ByMaNhomCotDiem.length; j++) {
                let giaTriCotDiem = DSHocSinh[i][DSCotDiem_ByMaNhomCotDiem[j].value];
                if (DSCotDiem_ByMaNhomCotDiem[j].LoaiCotDiem === CONSTANTS.FORMULA_COLUMN) {
                    const htmlValue = instance?.[0]?.records?.[i]?.[j + freezeColumns]?.element?.innerHTML;
                    if (htmlValue !== undefined && htmlValue !== null && htmlValue !== '') {
                        giaTriCotDiem = htmlValue;
                    } else {
                        const dbRecord = (apiData || []).find(x => x.HocSinhID === DSHocSinh[i].HocSinhID && x.MaCotDiem === DSCotDiem_ByMaNhomCotDiem[j].value);
                        giaTriCotDiem = dbRecord ? dbRecord.KetQuaDanhGia_VI : '';
                    }
                }
                if (DSCotDiem_ByMaNhomCotDiem[j].GiaTriCotDiem === 'number') {
                    giaTriCotDiem = (giaTriCotDiem === null || giaTriCotDiem === NaN || giaTriCotDiem === '')
                        ? ''
                        : parseFloat(giaTriCotDiem);
                }
                cotDiem_HS[DSCotDiem_ByMaNhomCotDiem[j].value] = giaTriCotDiem;
            }
            dataExcel.push(cotDiem_HS);
        }
        return dataExcel;
    }
};
// ==================== UTILITY SERVICE ====================
const UtilityService = {
    /** Lấy Tình Trạng để disable/enable UI */
    getTinhTrangStatus(DSHocSinh_API, vueData) {
        if (DSHocSinh_API.length === 0) {
            return { isDisabled: false, TinhTrang: null };
        }
        const priorityStudent = fn_ProrityTinhTrang(DSHocSinh_API);
        const tinhTrang = priorityStudent?.TinhTrang;
        const status = fn_IsDisabledTinhTrangDiem({
            TinhTrang: tinhTrang,
            type: 'GV',
            CapID: vueData.CapID
        });
        return {
            isDisabled: status.disabled,
            TinhTrang: tinhTrang,
            statusDetail: status
        };
    },
    /** Lấy thông tin từ chối */
    getReasonReject(DSHocSinh_API, vueData) {
        const defaultObj = { disabled: false, NoiDungNhanXet: null, TinhTrang: null };
        if (DSHocSinh_API.length === 0) return defaultObj;
        const obj = DSHocSinh_API.find(x => x.TinhTrang === 3 || x.TinhTrang === 5 || x.TinhTrang === 7);
        if (obj) {
            defaultObj.disabled = true;
            defaultObj.NoiDungNhanXet = obj.NoiDungNhanXet ?? '';
            defaultObj.TinhTrang = obj.TinhTrang ?? '';
        }
        return defaultObj;
    },
    /** Render text người từ chối */
    renderTextPersonReject(TinhTrang, vueData) {
        if (!TinhTrang) return '';
        const isLanguage = JSON.parse(localStorage.getItem('IsLanguage')) ?? false;
        let text = '';
        if (vueData.CapID === 1) {
            if (TinhTrang === 3) text = isLanguage ? 'Homeroom teacher rejected' : 'Giáo viên chủ nhiệm từ chối';
            if (TinhTrang === 5) text = isLanguage ? 'Department head rejected' : 'Tổ trưởng từ chối';
            if (TinhTrang === 7) text = isLanguage ? 'School board rejected' : 'BGH chủ nhiệm từ chối';
        } else {
            if (TinhTrang === 3) text = isLanguage ? 'School board rejected' : 'BGH từ chối';
        }
        return text;
    },
    /** Lấy điểm Test từ Theme */
    async getThemeTestScore(filter, DSHocSinh) {
        const maNhom = filter.MaNhomCotDiemItem.MaNhomCotDiem;
        const mapping = CONSTANTS.THEME_MAPPING[maNhom];
        if (!mapping) return DSHocSinh;
        const DSCotDiem_TA2 = await ApiService.fetchBangDiem(
            'lms/HocSinhBangDiem_Get_ByMonHocID_MaNhom',
            {
                LopID: filter.LopItem.LopID,
                MonHocID: filter.MonHocItem.MonHocID,
                TemplateBangDiemID: filter.MonHocItem.TemplateBangDiemID,
                MaNhomCotDiem: mapping.nhom
            }
        );
        const arrFilterDSCotDiemWithThemeTest = DSCotDiem_TA2.filter(x => x.MaCotDiem === mapping.cot);
        return DSHocSinh.map(hocSinh => {
            const cotDiemByHocSinh = arrFilterDSCotDiemWithThemeTest.find(
                x => x.HocSinhID === hocSinh.HocSinhID
            );
            if (cotDiemByHocSinh) {
                hocSinh[mapping.target] = cotDiemByHocSinh.KetQuaDanhGia_VI;
            }
            return hocSinh;
        });
    }
};
// ==================== TINH TRANG SERVICE ====================
const TinhTrangService = {
    /** Cập nhật tình trạng cho các môn NLPC liên quan (Cấp 1) */
    async updateTinhTrangNLPC(filter, vueData, tinhTrang = CONSTANTS.TINH_TRANG.LUU_TAM) {
        const ListMonHoc = filter.MonHocItem?.List_MonHoc_NLPC_ID;
        if (!ListMonHoc) {
            console.log("⚠️ Không có môn NLPC liên quan");
            return { success: true, count: 0 };
        }
        const monHocIDArray = ListMonHoc.split(",").map(id => id.trim()).filter(Boolean);
        console.log(`🔄 Bắt đầu cập nhật tình trạng ${tinhTrang} cho ${monHocIDArray.length} môn NLPC`);
        let successCount = 0;
        let errorCount = 0;
        const errors = [];
        for (const monHocID of monHocIDArray) {
            try {
                const monHocLopList = await ApiService.getMonHocLopByMonHocID({
                    MonHocID: monHocID,
                    LopID: filter.LopItem.LopID,
                    NienKhoa: vueData.NienKhoa
                });
                const MonHocLopID = monHocLopList[0]?.MonHocLopID;
                if (!MonHocLopID) {
                    console.warn(`⚠️ Không tìm thấy MonHocLopID cho MonHocID: ${monHocID}`);
                    errorCount++;
                    errors.push({ monHocID, error: 'MonHocLopID not found' });
                    continue;
                }
                const apiMethod = tinhTrang === CONSTANTS.TINH_TRANG.GUI_BGH
                    ? ApiService.updateTinhTrang
                    : ApiService.updateTinhTrangLuuTam;
                await apiMethod({
                    NienKhoa: vueData.NienKhoa,
                    MonHocLopID,
                    LopID: filter.LopItem.LopID,
                    TinhTrang: tinhTrang,
                    MaNhomCotDiem: filter.MaNhomCotDiemItem.MaNhomCotDiem
                });
                successCount++;
                console.log(`✅ Đã cập nhật tình trạng ${tinhTrang} cho MonHocID: ${monHocID}`);
            } catch (error) {
                errorCount++;
                errors.push({ monHocID, error: error.message });
                console.error(`❌ Lỗi khi cập nhật MonHocID ${monHocID}:`, error);
            }
        }
        console.log(`📊 Kết quả: ${successCount}/${monHocIDArray.length} thành công`);
        return { success: errorCount === 0, total: monHocIDArray.length, successCount, errorCount, errors };
    },
    /** Lưu tạm - Cập nhật tình trạng = 1 */
    async saveDraft(filter, vueData) {
        try {
            console.log("💾 Bắt đầu lưu tạm...");
            if ([2, 3].includes(vueData.CapID)) {
                await ApiService.updateTinhTrangC2C3({
                    NienKhoa: vueData.NienKhoa,
                    LopID: filter.LopItem.LopID,
                    MonHocLopID: filter.MonHocItem.MonHocLopID,
                    MaNhomCotDiem: filter.MaNhomCotDiemItem.MaNhomCotDiem,
                    TinhTrang: CONSTANTS.TINH_TRANG.LUU_TAM
                });
            } else {
                await ApiService.updateTinhTrangLuuTam({
                    NienKhoa: vueData.NienKhoa,
                    MonHocLopID: filter.MonHocItem.MonHocLopID,
                    LopID: filter.LopItem.LopID,
                    TinhTrang: CONSTANTS.TINH_TRANG.LUU_TAM,
                    MaNhomCotDiem: filter.MaNhomCotDiemItem.MaNhomCotDiem
                });
                await this.updateTinhTrangNLPC(filter, vueData, CONSTANTS.TINH_TRANG.LUU_TAM);
            }
            return { success: true };
        } catch (error) {
            console.error("❌ Lỗi khi lưu tạm:", error);
            throw error;
        }
    },
    /** Gửi BGH - Cập nhật tình trạng = 2 */
    async sendToBGH(filter, vueData) {
        try {
            console.log("📤 Bắt đầu gửi BGH...");
            if ([2, 3].includes(vueData.CapID)) {
                await ApiService.updateTinhTrangC2C3({
                    NienKhoa: vueData.NienKhoa,
                    LopID: filter.LopItem.LopID,
                    MonHocLopID: filter.MonHocItem.MonHocLopID,
                    MaNhomCotDiem: filter.MaNhomCotDiemItem.MaNhomCotDiem,
                    TinhTrang: CONSTANTS.TINH_TRANG.GUI_BGH
                });
            } else {
                await ApiService.updateTinhTrang({
                    NienKhoa: vueData.NienKhoa,
                    MonHocLopID: filter.MonHocItem.MonHocLopID,
                    LopID: filter.LopItem.LopID,
                    TinhTrang: CONSTANTS.TINH_TRANG.GUI_BGH,
                    MaNhomCotDiem: filter.MaNhomCotDiemItem.MaNhomCotDiem
                });
                await this.updateTinhTrangNLPC(filter, vueData, CONSTANTS.TINH_TRANG.LUU_TAM);
            }
            return { success: true };
        } catch (error) {
            console.error("❌ Lỗi khi gửi BGH:", error);
            throw error;
        }
    }
};
// ==================== LOCK SERVICE ====================
const LockService = {
    /**
     * Khóa một danh sách cột điểm của môn chính
     * @param {Array} columns - [{ value: MaCotDiem, title }]
     * @param {object} filter
     */
    async lockColumns(columns, filter) {
        for (const cotDiem of columns) {
            await ApiService.toggleKhoaCotDiem({
                LopID: filter.LopItem.LopID,
                MonHocLopID: cotDiem.MonHocLopID || filter.MonHocItem.MonHocLopID,
                MaCotDiem: cotDiem.MaCotDiemSave || ColumnCodeService.normalizeMaCotDiem(cotDiem.value),
                IsKhoaCotDiem: true
            });
        }
    },
    // Dựng payload thật từ JSpreadsheet và chỉ ghi log để kiểm tra; chưa gọi mark/lms_syncdiem.
    /** Ánh xạ mã cột LMS sang LoaiDiem mà mark/lms_syncdiem nhận. */
    getSyncLoaiDiemForColumn(column, filter, apiData = []) {
        const isEnglishSubject = CONSTANTS.ENGLISH_SUBJECTS.includes(Number(filter.MonHocItem?.MonHocID));
        const columnMeta = apiData.find(row =>
            ColumnCodeService.isSameMaCotDiem(row?.MaCotDiem, column?.value)
        );
        // LoaiDiem trong SELECT KQHT được suy ra từ MaCotDiem; không lấy theo nhóm đang lọc
        // để tránh cột như DiemTB bị gán nhầm thành GK/CK.
        const sources = [columnMeta?.MaCotDiem, column?.value, column?.MaCotDiemSave];
        for (const source of sources) {
            const normalized = String(source ?? '')
                .normalize('NFD')
                .replace(/[\u0300-\u036f]/g, '')
                .toUpperCase();
            // Theme_total của môn Anh C2/C3 là TX; LMS cũng xếp các mã kết thúc bằng Total vào TX.
            if (isEnglishSubject && /THEME[_\s-]*TOTAL/.test(normalized)) return 'TX';
            if (/DIEMCD1|DIEMGK|GIA\s*KY|MID[_\s-]*TOTAL[_\s-]*POINT/.test(normalized)) return 'DiemGK';
            if (/DIEMCD2|DIEMCK|CUOI\s*KY|FINAL[_\s-]*TOTAL[_\s-]*POINT/.test(normalized)) return 'DiemCK';
            if (/KTTX|DIEMTX|THUONG\s*XUYEN|(?:^|[_\s-])TX(?:\d|[_\s-]|$)|TOTAL$/.test(normalized)) return 'TX';
        }
        return null;
    },
    /** Loại điểm khác nhau cần đẩy, không gửi lặp khi khóa nhiều cột cùng nhóm. */
    getSyncLoaiDiem(columns, filter, apiData = []) {
        return [...new Set(columns
            .map(column => this.getSyncLoaiDiemForColumn(column, filter, apiData))
            .filter(Boolean))];
    },
    getSyncCellIndex(headers, columnCode) {
        return headers.findIndex(header => header?.name === columnCode ||
            ColumnCodeService.isSameMaCotDiem(header?.name, columnCode));
    },
    getSyncCellValue(row, index, key) {
        if (index < 0) return row && !Array.isArray(row) ? row[key] : undefined;
        return Array.isArray(row) ? row[index] : row?.[key];
    },
    toSyncNumber(value) {
        if (value === null || value === undefined || value === '') return null;
        const number = Number(value);
        return Number.isFinite(number) ? number : null;
    },
    normalizeSyncHocKy(value) {
        const semester = String(value ?? '').trim();
        return /^[12]$/.test(semester) ? `HK${semester}` : (semester || null);
    },
    /**
     * Tạo record theo đúng 12 key của SELECT LMS_KetQuaHocTap.
     * KetQua lấy từ JSpreadsheet; DSHocSinh_API chỉ cung cấp metadata cho các cột.
     */
    buildSyncDataFromSheet(columns, loaiDiem, filter, vueData, sheetInstance, headers, apiData = []) {
        const sheet = Array.isArray(sheetInstance) ? sheetInstance[0] : sheetInstance;
        if (!sheet || typeof sheet.getData !== 'function') {
            throw new Error('Bảng JSpreadsheet chưa sẵn sàng để lấy dữ liệu đồng bộ.');
        }
        const sheetRows = sheet.getData();
        if (!Array.isArray(sheetRows)) throw new Error('JSpreadsheet không trả về danh sách dòng dữ liệu.');
        const studentIdIndex = this.getSyncCellIndex(headers, 'HocSinhID');
        const soDanhBoIndex = this.getSyncCellIndex(headers, 'SoDanhBo');
        if (studentIdIndex < 0) throw new Error('Không tìm thấy cột HocSinhID trên JSpreadsheet.');
        const targetColumns = columns.map(column => {
            const columnMeta = apiData.find(row =>
                ColumnCodeService.isSameMaCotDiem(row?.MaCotDiem, column?.value)
            );
            if (this.getSyncLoaiDiemForColumn(column, filter, apiData) !== loaiDiem) return null;
            const maCotDiem = String(columnMeta?.MaCotDiem || column.MaCotDiemSave ||
                ColumnCodeService.normalizeMaCotDiem(column.value));
            const sheetColumnIndex = this.getSyncCellIndex(headers, maCotDiem);
            if (sheetColumnIndex < 0) throw new Error(`Không tìm thấy cột ${maCotDiem} trên JSpreadsheet.`);
            return { columnMeta, maCotDiem, sheetColumnIndex };
        }).filter(Boolean);
        const sortedCodes = [...targetColumns]
            .sort((left, right) => left.maCotDiem.localeCompare(right.maCotDiem))
            .map(item => item.maCotDiem);
        const result = [];
        sheetRows.forEach((sheetRow, rowIndex) => {
            const hocSinhID = this.getSyncCellValue(sheetRow, studentIdIndex, 'HocSinhID');
            if (hocSinhID === null || hocSinhID === undefined || hocSinhID === '') return;
            const studentMeta = apiData.find(row => String(row?.HocSinhID) === String(hocSinhID));
            targetColumns.forEach(target => {
                const cellMeta = apiData.find(row =>
                    String(row?.HocSinhID) === String(hocSinhID) &&
                    ColumnCodeService.isSameMaCotDiem(row?.MaCotDiem, target.maCotDiem)
                ) || target.columnMeta;
                let ketQua = this.getSyncCellValue(sheetRow, target.sheetColumnIndex, target.maCotDiem);
                if (cellMeta?.Formula || cellMeta?.LoaiCotDiem === CONSTANTS.FORMULA_COLUMN) {
                    const formulaCell = sheet.records?.[rowIndex]?.[target.sheetColumnIndex]?.element;
                    const displayedValue = formulaCell?.textContent?.trim();
                    if (displayedValue) ketQua = displayedValue;
                    else if (formulaCell?.innerHTML != null) ketQua = formulaCell.innerHTML;
                }
                if (ketQua && typeof ketQua === 'object') {
                    ketQua = ketQua.value ?? ketQua.text ?? ketQua.name ?? JSON.stringify(ketQua);
                }
                const monHocCode = cellMeta?.MonHocCode ?? target.columnMeta?.MonHocCode ??
                    filter.MonHocItem?.MonHocCode;
                if (monHocCode == null || String(monHocCode).trim() === '') {
                    throw new Error('Không tìm thấy MonHocCode để tạo dữ liệu đồng bộ điểm.');
                }
                const semester = cellMeta?.HocKy ?? cellMeta?.Semester ??
                    target.columnMeta?.HocKy ?? target.columnMeta?.Semester ??
                    filter.MaNhomCotDiemItem?.Semester ?? vueData.NienKhoaItem?.HocKi;
                const fallbackThuTuCotDiem = sortedCodes.indexOf(target.maCotDiem) + 1;
                result.push({
                    LopID: String(cellMeta?.LopID ?? filter.LopItem?.LopID ?? ''),
                    TenLop: cellMeta?.TenLop ?? filter.LopItem?.TenLop ?? '',
                    SoDanhBo: this.getSyncCellValue(sheetRow, soDanhBoIndex, 'SoDanhBo') ?? studentMeta?.SoDanhBo ?? null,
                    HocSinhID: this.toSyncNumber(hocSinhID),
                    MonHocCode: monHocCode == null ? null : String(monHocCode),
                    LoaiDiem: loaiDiem,
                    ThuTuNhom: this.toSyncNumber(cellMeta?.ThuTuNhom ?? target.columnMeta?.ThuTuNhom ??
                        filter.MaNhomCotDiemItem?.ThuTuNhom),
                    ThuTuCotDiem: this.toSyncNumber(cellMeta?.ThuTuCotDiem ?? target.columnMeta?.ThuTuCotDiem ??
                        fallbackThuTuCotDiem),
                    MaCotDiem: target.maCotDiem,
                    KetQua: ketQua === null || ketQua === undefined || String(ketQua).trim() === ''
                        ? null
                        : String(ketQua).trim(),
                    HocKy: this.normalizeSyncHocKy(semester),
                    Sort: this.toSyncNumber(cellMeta?.Sort ?? target.columnMeta?.Sort ?? filter.MonHocItem?.Sort)
                });
            });
        });
        return result;
    },
    /**
     * Dựng và log payload theo schema LMS_KetQuaHocTap để kiểm tra trước; chưa gửi request sang QLDiem.
     * Chỉ cấp 2/3 có payload; API thật vẫn được giữ comment.
     */
    async logLmsSyncDiemParamsAfterLock(columns, filter, vueData, sheetInstance, headers, apiData = []) {
        const capHoc = Number(vueData.CapID);
        if (![2, 3].includes(capHoc)) return { loggedTypes: [] };
        const khoiID = Number(filter.KhoiItem?.KhoiID);
        const rawHocKy = vueData.NienKhoaItem?.HocKi ?? filter.MaNhomCotDiemItem?.Semester;
        const hocKyMatch = String(rawHocKy ?? '').match(/([12])\s*$/);
        const hocKy = hocKyMatch ? Number(hocKyMatch[1]) : Number(rawHocKy);
        if (!Number.isInteger(khoiID) || ![1, 2].includes(hocKy)) {
            throw new Error('Thiếu Khối hoặc Học kỳ hợp lệ để đồng bộ điểm sang QLDiem.');
        }
        const loaiDiemList = this.getSyncLoaiDiem(columns, filter, apiData);
        for (const loaiDiem of loaiDiemList) {
            const rows = this.buildSyncDataFromSheet(
                columns, loaiDiem, filter, vueData, sheetInstance, headers, apiData
            );
            if (!rows.length) continue;
            const params = {
                KhoiID: khoiID,
                LoaiDiem: loaiDiem,
                HocKy: hocKy,
                Data: JSON.stringify(rows)
            };
            console.log('[mark/lms_syncdiem] params:', params);
            // Giữ request tắt để bạn kiểm tra payload trên console trước.
            // await ApiService.syncDiemToQLDiem(params);
        }
        return { loggedTypes: loaiDiemList };
    },
    /**
     * Mở khóa một danh sách cột điểm của môn chính
     * @param {Array} columns - [{ value: MaCotDiem, KhoaCotDiemID }]
     * @param {object} filter
     * @param {string} reason
     */
    async unlockColumns(columns, filter, reason) {
        for (const cotDiem of columns) {
            if (!cotDiem.KhoaCotDiemID) continue;
            await ApiService.updateKhoaCotDiemTinhTrang({
                KhoaCotDiemID: cotDiem.KhoaCotDiemID,
                TinhTrang: 0,
                LyDo: reason
            });
        }
    },
    /**
     * Khóa toàn bộ cột điểm của các môn NLPC đi kèm
     * @param {object} filter
     * @param {object} vueData
     * @param {Array} dsHocSinhAPI - để lấy danh sách MaCotDiem theo MonHocID
     * @returns {{ count: number }}
     */
    async lockNLPCColumns(filter, vueData, dsHocSinhAPI) {
        const nlpcIDList = filter.MonHocItem?.List_MonHoc_NLPC_ID
            ? filter.MonHocItem.List_MonHoc_NLPC_ID.split(',').map(id => id.trim()).filter(Boolean)
            : [];
        if (!nlpcIDList.length) return { count: 0 };
        let lockedCount = 0;
        for (const monHocID of nlpcIDList) {
            try {
                const monHocIDNum = parseInt(monHocID);
                const monHocLopList = await ApiService.getMonHocLopByMonHocID({
                    MonHocID: monHocIDNum,
                    LopID: filter.LopItem.LopID,
                    NienKhoa: vueData.NienKhoa
                });
                const MonHocLopID = monHocLopList?.[0]?.MonHocLopID;
                if (!MonHocLopID) {
                    console.warn(`⚠️ Không tìm thấy MonHocLopID cho MonHocID: ${monHocIDNum}`);
                    continue;
                }
                const maCotDiemList = [
                    ...new Set(
                        dsHocSinhAPI
                            .filter(x => x.MonHocID === monHocIDNum)
                            .map(x => x.MaCotDiem)
                    )
                ];
                for (const maCotDiem of maCotDiemList) {
                    await ApiService.toggleKhoaCotDiem({
                        LopID: filter.LopItem.LopID,
                        MonHocLopID,
                        MaCotDiem: maCotDiem,
                        IsKhoaCotDiem: true
                    });
                }
                lockedCount++;
                console.log(`✅ Đã khóa ${maCotDiemList.length} cột môn NLPC MonHocID: ${monHocIDNum}`);
            } catch (error) {
                console.error(`❌ Lỗi khi khóa môn NLPC MonHocID ${monHocID}:`, error);
            }
        }
        return { count: lockedCount };
    }
};
// ==================== MAIN SERVICE ====================
const BangDiemService = {
    constants: CONSTANTS,
    api: ApiService,
    filter: FilterService,
    data: DataProcessor,
    header: HeaderBuilder,
    formula: FormulaProcessor,
    style: StyleService,
    export: ExportService,
    utility: UtilityService,
    tinhTrang: TinhTrangService,
    lock: LockService,
    /** Khởi tạo dữ liệu bảng điểm hoàn chỉnh */
    async initialize(filter, vueData) {
        try {
            if (!this.filter.isValidFilter(filter)) {
                return {
                    students: [], headers: [], nestedHeaders: [], freezeColumns: 3,
                    styleSheet: {}, comments: {}, apiData: [], lockedColumns: [],
                    DSCotDiem_ByMaNhomCotDiem: [],
                    tinhTrangStatus: { isDisabled: false, TinhTrang: null }
                };
            }
            // 1. Fetch STEM config
            let stemConfigList = [];
            if (filter.MonHocItem.MonHocID === CONSTANTS.SUBJECT_IDS.STEM_36) {
                stemConfigList = StemModeService.normalizeConfigList(await this.api.getSTEMConfig({
                    NienKhoa: vueData.NienKhoa,
                    KhoiID: filter.KhoiItem.KhoiID
                }));
            }
            const isLegacyStem = filter.MonHocItem.MonHocID === CONSTANTS.SUBJECT_IDS.STEM_36 &&
                StemModeService.hasLegacyConfig(stemConfigList);
            // 2. Fetch data
            const action = this.filter.getBangDiemAction(filter, vueData, stemConfigList);
            const apiData = await this.api.fetchBangDiem(action, {
                LopID: filter.LopItem.LopID,
                MonHocID: filter.MonHocItem.MonHocID,
                TemplateBangDiemID: filter.MonHocItem.TemplateBangDiemID,
                MaNhomCotDiem: filter.MaNhomCotDiemItem.MaNhomCotDiem,
                ThuTuNhom: filter.MaNhomCotDiemItem.ThuTuNhom,
                Semester: filter.MaNhomCotDiemItem.Semester,
                NienKhoa: vueData.NienKhoa,
                KhoiID: filter.KhoiItem?.KhoiID
            });
            if (!apiData?.length) {
                return {
                    students: [], headers: [], nestedHeaders: [], freezeColumns: 3,
                    styleSheet: {}, comments: {}, apiData: [], lockedColumns: [],
                    displayColumns: [], DSCotDiem_ByMaNhomCotDiem: [],
                    tinhTrangStatus: { isDisabled: false, TinhTrang: null }
                };
            }
            // 3. Tình trạng
            const tinhTrangStatus = this.utility.getTinhTrangStatus(apiData, vueData);
            // 4. Students
            const students = this.data.processStudentList(apiData);
            // 5. Freeze columns
            const isEnglish = this.filter.isEnglishSubject(filter.MonHocItem.MonHocID);
            const isGroup = this.filter.isGroupSubject(filter.MonHocItem.MonHocID);
            const freezeColumns = this.data.calculateFreezeColumns(filter.MonHocItem.MonHocID, isEnglish, isGroup);
            // 6. Locked columns
            const lockedColumnsRaw = await this.api.getKhoaCotDiem({
                LopID: filter.LopItem.LopID,
                MonHocLopID: filter.MonHocItem.MonHocLopID,
                MaNhomCotDiem: filter.MaNhomCotDiemItem.MaNhomCotDiem,
                Semester: filter.MaNhomCotDiemItem.Semester,
                NienKhoa: vueData.NienKhoa
            });
            const lockedColumns = (lockedColumnsRaw ?? []).filter(x => {
                const isSameLop = x?.LopID == null || String(x.LopID) === String(filter.LopItem.LopID);
                return isSameLop;
            });
            const isLanguage = JSON.parse(localStorage.getItem('IsLanguage')) ?? false;
            const firstStudent = fn_ProrityTinhTrang(students);
            const gradeColumns = apiData.filter(x => x.HocSinhID === firstStudent.HocSinhID);
            const DSCotDiem_ByMaNhomCotDiem = gradeColumns.map(x => ({
                title: isLanguage ? (x.TenCotDiem_EN || x.TenCotDiem_VI) : x.TenCotDiem_VI,
                value: x.MaCotDiem,
                LoaiCotDiem: x.LoaiCotDiem,
                GiaTriCotDiem: x.GiaTriCotDiem,
                Formula: x.Formula
            }));
            console.log("gradeColumns", gradeColumns);
            const headers = [
                ...this.header.buildStudentInfoColumns(isGroup, isEnglish),
                ...gradeColumns.map(col =>
                    this.header.buildGradeColumn(col, isEnglish, tinhTrangStatus.isDisabled, lockedColumns)
                )
            ];
            const nestedHeaders = this.header.buildNestedHeaders(gradeColumns, apiData, freezeColumns, isGroup);
            const displayColumns = DSCotDiem_ByMaNhomCotDiem.map(cotDiem => {
                const matchedCols = lockedColumns.filter(x =>
                    ColumnCodeService.isSameMaCotDiem(x.MaCotDiem, cotDiem.value)
                );
                const lockedCol = matchedCols.find(x => x.TinhTrang === true)
                    || matchedCols.sort((a, b) => Number(b.KhoaCotDiemID || 0) - Number(a.KhoaCotDiemID || 0))[0];
                return {
                    title: cotDiem.title,
                    value: cotDiem.value,
                    isLocked: !!lockedCol?.TinhTrang,
                    KhoaCotDiemID: lockedCol?.KhoaCotDiemID || null,
                    MonHocLopID: lockedCol?.MonHocLopID || filter.MonHocItem.MonHocLopID,
                    MaCotDiemSave: ColumnCodeService.normalizeMaCotDiem(cotDiem.value)
                };
            });
            // 8. Data rows
            const dataRows = this.buildDataRows(
                students, apiData, filter, headers, freezeColumns, isEnglish, vueData, isLegacyStem
            );
            // 9. Styles & comments
            const styleSheet = this.style.applyBackgroundStyles(dataRows, gradeColumns, freezeColumns);
            const comments = this.style.applyComments(dataRows, gradeColumns, apiData, freezeColumns);
            return {
                students: dataRows, headers, nestedHeaders, freezeColumns,
                styleSheet, comments, apiData, lockedColumns,
                displayColumns, DSCotDiem_ByMaNhomCotDiem, tinhTrangStatus
            };
        } catch (error) {
            console.error('BangDiemService.initialize error:', error);
            throw error;
        }
    },
    /** Build data rows */
    buildDataRows(students, apiData, filter, headers, freezeColumns, isEnglish, vueData, isLegacyStem) {
        return students.map((student, rowIndex) => {
            const gradeColumns = apiData.filter(x => x.HocSinhID === student.HocSinhID);
            const rowData = {
                HocSinhID: student.HocSinhID,
                HoVaTenHocSinh: `${student.Ho} ${student.Ten}`,
                SoDanhBo: student.SoDanhBo
            };
            if (this.filter.isGroupSubject(filter.MonHocItem.MonHocID)) {
                rowData.TenLop = gradeColumns[0]?.TenLop;
            }
            if (isEnglish) {
                rowData.EnglishName = gradeColumns[0]?.EnglishName;
            }
            gradeColumns.forEach(column => {
                rowData[column.MaCotDiem] = this.processColumnValue(
                    column, gradeColumns, rowIndex + 1,
                    filter, headers, freezeColumns, isEnglish, vueData, isLegacyStem
                );
            });
            return rowData;
        });
    },
    /** Process column value */
    processColumnValue(column, allColumns, rowIndex, filter, headers, freezeColumns, isEnglish, vueData, isLegacyStem) {
        if (column.LoaiCotDiem !== CONSTANTS.FORMULA_COLUMN) {
            return this.data.processNonFormulaValue(column);
        }
        return this.formula.processFormulaValue(
            column, allColumns, rowIndex, filter, headers, freezeColumns, isEnglish, vueData, isLegacyStem
        );
    },
    /** Lưu dữ liệu */
    async saveData(editedCells, DSHocSinh, DSHocSinh_API, freezeColumns, filter, instance, vueData) {
        if (editedCells.length === 0) {
            Vue.$toast.warning("Bạn chưa điều chỉnh hoặc nhập điểm", { position: "top" });
            return;
        }
        const data = this.data.processBeforePushAPI(
            editedCells, DSHocSinh, DSHocSinh_API, freezeColumns, filter, instance
        );
        if (!data) return false;
        const hasError = data.some(item => item.IsError === 1);
        if (hasError) {
            Vue.$toast.error('Cột điểm chỉ cho phép nhập thang điểm 10!', { position: 'top' });
            return false;
        }
        await this.api.saveGradeData({
            NienKhoa: vueData.NienKhoa,
            MonHocLopID: filter.MonHocItem.MonHocLopID,
            LopID: filter.LopItem.LopID,
            MonHocID: filter.MonHocItem.MonHocID,
            TemplateBangDiemID: filter.MonHocItem.TemplateBangDiemID,
            MaNhomCotDiem: filter.MaNhomCotDiemItem.MaNhomCotDiem,
            KetQuaObjArr: data
        });
        return true;
    },
    /** Lưu tạm */
    async saveDraft(filter, vueData) {
        return await this.tinhTrang.saveDraft(filter, vueData);
    },
    /** Gửi BGH */
    async sendToBGH(filter, vueData) {
        return await this.tinhTrang.sendToBGH(filter, vueData);
    }
};