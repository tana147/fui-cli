function convertJsonToTree(data) {
    const jsonData = data.data ?? data
    if (jsonData) {
        const jsonTree = jsonData.reduce(
            (acc, curr) => {
                if (acc.parentMap[curr.parent_id]) {
                    ; (acc.parentMap[curr.parent_id].children = acc.parentMap[curr.parent_id].children || []).push(curr)
                } else {
                    acc.res.push(curr)
                }
                acc.parentMap[curr.id] = curr
                return acc
            },
            { parentMap: {}, res: [] },
        )
        return jsonTree.res
    } else {
        return []
    }
}

function showToast(obj) {
    if (!obj) {
        return
    }
    obj.type = obj.type === "green" ? "success" : "error"
    Vue.$toast[obj.type](obj.title, { position: "top" })
}

function formatPrice(value) {
    if (value) {
        value = value.toString().replace(/\./g, "")
        value = value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
    }
    return value
}

function uuidv4() {
    return "xxxxxxxxxx".replace(/[xy]/g, function (c) {
        const r = (Math.random() * 16) | 0,
            v = c == "x" ? r : (r & 0x3) | 0x8
        return v.toString(16).toUpperCase()
    })
}

function timeAgo(date, time) {
    const inputDate = new Date(`${date}T${time}`)
    const currentDate = new Date()
    const timeDifference = currentDate - inputDate
    const seconds = Math.floor(timeDifference / 1000)
    const minutes = Math.floor(seconds / 60)
    return minutes
}

function convertAlphabet(str) {
    str = str.toLowerCase()
    str = str.replace(/à|á|ạ|ả|ã|â|ầ|ấ|ậ|ẩ|ẫ|ă|ằ|ắ|ặ|ẳ|ẵ/g, "a")
    str = str.replace(/è|é|ẹ|ẻ|ẽ|ê|ề|ế|ệ|ể|ễ/g, "e")
    str = str.replace(/ì|í|ị|ỉ|ĩ/g, "i")
    str = str.replace(/ò|ó|ọ|ỏ|õ|ô|ồ|ố|ộ|ổ|ỗ|ơ|ờ|ớ|ợ|ở|ỡ/g, "o")
    str = str.replace(/ù|ú|ụ|ủ|ũ|ư|ừ|ứ|ự|ử|ữ/g, "u")
    str = str.replace(/ỳ|ý|ỵ|ỷ|ỹ/g, "y")
    str = str.replace(/đ/g, "d")
    str = str.replace(/\u0300|\u0301|\u0303|\u0309|\u0323/g, "") // Huyền sắc hỏi ngã nặng
    str = str.replace(/\u02C6|\u0306|\u031B/g, "") // Â, Ê, Ă, Ơ, Ư
    return str
}

function toSlug(str) {
    str = str.toLowerCase()
    str = str
        .normalize("NFD") // chuyển chuỗi sang unicode tổ hợp
        .replace(/[\u0300-\u036f]/g, "") // xóa các ký tự dấu sau khi tách tổ hợp
    str = str.replace(/[đĐ]/g, "d")
    str = str.replace(/([^0-9a-z-\s])/g, "")
    str = str.replace(/(\s+)/g, "-")
    str = str.replace(/-+/g, "-")
    str = str.replace(/^-+|-+$/g, "")
    return str
}

function debounce(fn, delay) {
    var timeoutID = null
    return function () {
        clearTimeout(timeoutID)
        var args = arguments
        var that = this
        timeoutID = setTimeout(function () {
            fn.apply(that, args)
        }, delay)
    }
}

function trimWhitespace(text) {
    let _text = ""
    if (text) {
        _text = text.replace(/\s+/g, "")
    }
    return _text
}

function toggleFullScreen() {
    const elem = document.body
    // ## The below if statement seems to work better ## if ((document.fullScreenElement && document.fullScreenElement !== null) || (document.msfullscreenElement && document.msfullscreenElement !== null) || (!document.mozFullScreen && !document.webkitIsFullScreen)) {
    if ((document.fullScreenElement !== undefined && document.fullScreenElement === null) || (document.msFullscreenElement !== undefined && document.msFullscreenElement === null) || (document.mozFullScreen !== undefined && !document.mozFullScreen) || (document.webkitIsFullScreen !== undefined && !document.webkitIsFullScreen)) {
        if (elem.requestFullScreen) {
            elem.requestFullScreen()
        } else if (elem.mozRequestFullScreen) {
            elem.mozRequestFullScreen()
        } else if (elem.webkitRequestFullScreen) {
            elem.webkitRequestFullScreen(Element.ALLOW_KEYBOARD_INPUT)
        } else if (elem.msRequestFullscreen) {
            elem.msRequestFullscreen()
        }
    } else {
        if (document.cancelFullScreen) {
            document.cancelFullScreen()
        } else if (document.mozCancelFullScreen) {
            document.mozCancelFullScreen()
        } else if (document.webkitCancelFullScreen) {
            document.webkitCancelFullScreen()
        } else if (document.msExitFullscreen) {
            document.msExitFullscreen()
        }
    }
}

function checkNumber(number) {
    return number !== "" && !isNaN(number)
}

function renderQRCodePayment(data, options) {
    if (!options) return
    const { Amount, CuaHangID, MaKH, MaHoaDon } = data
    const Ver_Data_ID00 = "000201"
    const Type_Init_ID01 = "010211"
    const TTDD_ID38 = "38" // Thông tin định danh ĐVCNTT (ID 02-51) --> ID 38 được sử dụng cho dịch vụ VietQR qua hệ thống Napas.
    const TTDD_ID38_GUID = "00" + "10A000000727" // '00': là ID"; '10': độ dài của 'A000000727'; ID: luôn có giá trị 'A000000727'.
    const TTDD_ID38_Bank_Head = "00" + `${String(options?.MaNganHang?.length).padStart(2, '0')}` + options?.MaNganHang //options?.MaNganHang //'00': là ID của Tổ chức thụ hưởng; '06' độ dài của Bin của ngân hàng (970418:BIDV) (tra ở : https://api.vietqr.io/v2/banks)
    const TTDD_ID38_Bank_Tail = "01" + `${String(options?.SoTaiKhoan?.length).padStart(2, '0')}` + options?.SoTaiKhoan //Cũ: "6790439391"; //'01:id;  '10': độ dài của bank id; '6701011230': Tài khoản của BIDV ZEN //'09007440476'; //Tài khoản BANK của anh Tâm //Số '6790439391' TK của DIM SUM
    let TTDD_ID38_Bank_Info = "01" + String((TTDD_ID38_Bank_Head + TTDD_ID38_Bank_Tail).length).padStart(2, "0") + TTDD_ID38_Bank_Head + TTDD_ID38_Bank_Tail
    const Sevice_Code = "0208QRIBFTTA" //'02' mã dịch vụ: ; QRIBFTTC: dịch vụ chuyển nhanh NAPAS247 bằng mã QR đến thẻ // QRIBFTTA: dịch vụ chuyển nhanh NAPAS247 bằng mã QR đến Tài khoản.
    let format_ID38 = TTDD_ID38_GUID + TTDD_ID38_Bank_Info + Sevice_Code
    let DVCNTT_ID02_51 = TTDD_ID38 + String(format_ID38.length).padStart(2, "0") + format_ID38 //let DVCNTT_ID02_51 =  '38530010A0000007270123000697044101'; //của anh Tâm
    const Money_Code_ID53 = "5303704"
    const Country_Code_ID58 = "5802VN"
    let InfoNote_ID62 = ""
    let CRC_ID63 = "6304"
    let Money_Trans_ID54 = ""
    Money_Trans_ID54 = "54" + String(String(Amount).length).padStart(2, "0") + Amount
    const formatInfo62 = CuaHangID + " " + MaHoaDon
    let info62 = "08" + String(formatInfo62.length).padStart(2, "0") + formatInfo62 // theo  InfoNote_ID62 phần ghi chú lệnh chuyển set cho nó mã 08
    InfoNote_ID62 = "62" + String(info62.length).padStart(2, "0") + info62
    let QRCODE = ""
    QRCODE = Ver_Data_ID00 + Type_Init_ID01 + DVCNTT_ID02_51 + Money_Code_ID53 + Money_Trans_ID54 + Country_Code_ID58 + InfoNote_ID62
    CRC_ID63 = crc16_ccitt(QRCODE + CRC_ID63)
    QRPayment = QRCODE + "6304" + CRC_ID63
    return QRPayment
}

function crc16_ccitt(data) {
    let crc = 0xffff
    for (let i = 0; i < data.length; i++) {
        crc ^= data.charCodeAt(i) << 8
        for (let j = 0; j < 8; j++) {
            if (crc & 0x8000) {
                crc = (crc << 1) ^ 0x1021
            } else {
                crc = crc << 1
            }
        }
    }
    return (crc & 0xffff).toString(16).padStart(4, "0").toUpperCase()
}
