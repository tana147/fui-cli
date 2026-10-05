if (typeof window !== 'undefined') {
    if (!window.errorState) {
        window.errorState = {
            ui: { visible: false, message: '', show: function() {}, hide: function() {} },
            api: { visible: false, message: '', code: null, status: null, show: function() {}, hide: function() {} }
        };
    }
    if (!window.loadingState) {
        window.loadingState = { count: 0, text: 'Đang xử lý...', get loading() { return false; } };
    }
    if (!window.staleDataState) {
        window.staleDataState = { visible: false, retryCallback: null, show: function() {}, hide: function() {} };
    }
}

async function GET_NienKhoa_Info(){
    const res = await new Promise((resolve, reject) => {
        ajaxCALL('lms/NienKhoa_Get',{}, res => {
            let NienKhoa_HocKi_Enable = res.data.find(hk => hk.IsActive)
            resolve(NienKhoa_HocKi_Enable)
        })
    })
    return res
}

async function API_Promise(url,payload={}){
    const res = await new Promise((resolve, reject) => {
        ajaxCALL(url,payload, res => {
            resolve(res.data)
        })
    })
    return res
}