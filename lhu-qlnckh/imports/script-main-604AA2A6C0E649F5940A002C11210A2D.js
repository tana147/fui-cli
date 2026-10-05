$(document).ready(function () {
    ImportChartLabelsPlugin()
    ensureXlsxLoaded()
    registerGlobalJsonToExcel()
});

const XLSX_CDN_URL = 'https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js';

function ensureXlsxLoaded(callback) {
    if (typeof XLSX !== 'undefined') {
        if (typeof callback === 'function') callback();
        return;
    }
    const existingScript = document.querySelector(`script[src="${XLSX_CDN_URL}"]`);
    if (existingScript) {
        if (typeof callback === 'function') {
            existingScript.addEventListener('load', () => callback(), { once: true });
        }
        return;
    }
    const script = document.createElement('script');
    script.src = XLSX_CDN_URL;
    script.async = true;
    script.onload = function () {
        if (typeof callback === 'function') callback();
    };
    document.head.appendChild(script);
}

const formatAsCurrency = (value, dec) => {
    dec = dec || 0
    if (value === null || value === undefined) {
        return 0
    }
    return '' + value.toFixed(dec).replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,")
}

const convertDiem = (number) => {
    let _number = 0
    if (Number.isInteger(number) || number === null) {
        _number = Number(number ?? 0).toFixed(1);
    } else {
        _number = number
    }
    return _number
}

function getColorStatusAnPham(TrangThaiID) {
    let trangthaiColor = ""
    if (TrangThaiID === 1) {
        trangthaiColor = ""
    }
    if (TrangThaiID === 2) {
        trangthaiColor = "warning"
    }
    if (TrangThaiID === 3) {
        trangthaiColor = "primary"
    }
    if (TrangThaiID === 4) {
        trangthaiColor = "success"
    }
    if (TrangThaiID === 5) {
        trangthaiColor = "error"
    }
    if (TrangThaiID === 6) {
        trangthaiColor = ""
    }
    return trangthaiColor
}

function ImportChartLabelsPlugin() {
    if (typeof Chart !== 'undefined' && typeof ChartDataLabels !== 'undefined') {
        Chart.register(ChartDataLabels);
    }
}

function ajaxCALLPromise(url, params = null) {
    return new Promise(resolve => {
        ajaxCALL(url, params, res => resolve(res.data))
    })
}

function jsonToExcel(options = {}) {
    const {
        data = [],
        filename = 'Export.xlsx',
        worksheet = 'Sheet1'
    } = options

    if (!Array.isArray(data) || data.length === 0) {
        if (typeof Vue !== 'undefined' && Vue.$toast) {
            Vue.$toast.warning('Không có dữ liệu để xuất Excel', { position: 'top' })
        }
        return
    }

    const finalFilename = String(filename).endsWith('.xlsx') ? String(filename) : `${filename}.xlsx`

    const writeExcelFile = () => {
        const ws = XLSX.utils.json_to_sheet(data)
        const wb = XLSX.utils.book_new()
        XLSX.utils.book_append_sheet(wb, ws, worksheet)
        XLSX.writeFile(wb, finalFilename)
    }

    ensureXlsxLoaded(writeExcelFile)
}

function registerGlobalJsonToExcel() {
    window.jsonToExcel = jsonToExcel
    if (typeof Vue !== 'undefined' && Vue.prototype) {
        Vue.prototype.jsonToExcel = jsonToExcel
    }
}

registerGlobalJsonToExcel()
