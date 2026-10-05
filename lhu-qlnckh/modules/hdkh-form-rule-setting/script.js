
async function initPage() {
    vueData.formID = new URLSearchParams(window.location.search).get('FormID');
    if (vueData.formID) {
        runAction('getFormInfo');
        runAction('getDSFields');
        vueData.DM_GetALL = new Map()
        // all Danh Muc
        const data_DM_All = await ajaxCALLPromise("/HDKH_DM_GetAll")
        for (let i = 0; i <= data_DM_All.length; i++) {
            let item = data_DM_All[i] ?? {};
            vueData.DM_GetALL.set(item[0]?.DanhMucCode, data_DM_All[i])
        }
        const response = await ajaxCALLPromise('/HDKH_Rule_GetListByForm', { FormID: vueData.formID })
        const rawRules = response ?? [];
        if (!Array.isArray(rawRules)) {
            console.error("Dữ liệu trả về từ API HDKH_Rule_GetListByForm không phải là một mảng:", rawRules);
            vueData.dsRules = [];
            return;
        }
        const processedRules = rawRules.map(rule => {
            let conditionsHtml = '';
            let resultHtml = '';
            let conditions = [];
            // 1. Xử lý và tạo HTML cho cột "Điều kiện (IF)"
            try {
                if (typeof rule.json_data === 'string' && rule.json_data) {
                    conditions = JSON.parse(rule.json_data);
                } else {
                    conditions = rule.json_data || [];
                }
                if (conditions.length > 0) {
                    conditions.forEach(condition => {
                        condition.DataSource = vueData.getDataSourceByFieldID(condition.FieldID)
                        condition.DataSourceItems = vueData.fetchDataSourceForField(condition)
                        condition.ConditionValue = Number(condition.ConditionValue);
                    })
                    conditionsHtml = conditions.map(c => {
                        const item = c.DataSourceItems.find(item => item.value === c.ConditionValue);
                        return `<div class="d-block mb-1">• ${c.FieldLabel} ${c.Operator} <strong>${item?.title || ''}</strong></div>`;
                    }).join('');
                } else {
                    conditionsHtml = '<i class="text-grey">Luôn áp dụng</i>';
                }
            } catch (e) {
                console.error('Lỗi parse JSON cho RuleID:', rule.RuleID, e);
                conditionsHtml = '<i class="text-error">Lỗi dữ liệu điều kiện</i>';
            }
            // 2. Xử lý và tạo HTML cho cột "Kết quả (THEN)"
            const QuyTacPhanChia = vueData.DSQuyTacPhanChia.find(item => item.value === rule.MaQuyTacPhanChia)
            resultHtml = `<div><strong>${rule.SoGioQuyDoi_Goc} giờ</strong> (${QuyTacPhanChia?.title || ''})</div>`;
            if (rule.Apply_AP_Index) {
                resultHtml += '<div class="text-caption text-blue">+ Áp dụng AP Index</div>';
            }
            // 3. Trả về object rule mới đã chứa sẵn các chuỗi HTML
            return {
                ...rule,
                Conditions_HTML: conditionsHtml,
                Result_HTML: resultHtml,
                Conditions: conditions
            };
        });
        vueData.dsRules = processedRules;
    } else {
        console.error("Không tìm thấy FormID trong URL.");
        Vue.$toast.error('Thiếu thông tin Form để tải quy tắc.', { position: "top" });
    }
}
function openNewRuleDialog() {
    vueData.selectedRule = null;
    Vue.nextTick(function () {
        vueData.selectedRule = {
            FormID: vueData.formID,
            Conditions: [],
            json_data: '[]' // Thêm json_data để đồng bộ cấu trúc
        };
        vueData.dialogTitle = "Thêm mới Quy tắc Tính điểm";
        vueData.isShowDialog = true;
    });
}
function confirmAction(title, api, params) {
    let paramsConfirm = { ...params }
    let titleConfirm = title
    let apiConfirm = api
    confirm({
        title: titleConfirm,
        action: function () {
            ajaxCALL(apiConfirm, paramsConfirm, res => {
                initPage()
            })
        },
        onclose: {} //Action all raw
    })
}
function getAllDM() {
    ajaxCALL('/HDKH_DM_GetAll', null, res => {
        if (res.data.length == 0) return
        for (let i = 0; i <= res.data.length; i++) {
            let item = res.data[i] ?? {};
            vueData.DM_GetALL.set(item[0]?.DanhMucCode, res.data[i])
        }
    });
}
function getDataSourceByFieldID(fieldID) {
    const field = vueData.dsFieldsForRule.find(({ FieldID }) => FieldID == fieldID)
    return field.DataSource ?? null
}
function fetchDataSourceForField(condition) {
    if (!condition.DataSource) return;
    let DataSourceReplaceDM_ = condition.DataSource.includes('DM_') ? condition.DataSource.replace('DM_', '') : condition.DataSource
    const data = vueData.DM_GetALL.get(DataSourceReplaceDM_);
    return Array.isArray(data) ? data : []
}
// Đăng ký các hàm vào vueData
vueData.initPage = initPage;
vueData.confirmAction = confirmAction
vueData.openNewRuleDialog = openNewRuleDialog;
vueData.getDataSourceByFieldID = getDataSourceByFieldID;
vueData.fetchDataSourceForField = fetchDataSourceForField;