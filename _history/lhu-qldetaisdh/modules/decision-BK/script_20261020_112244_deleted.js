function onDetailDecision(DecisionID) {
    console.log('test', DecisionID)
    vueData.isDetailDialog = true
    ajaxCALL(
        '/Decision_Get_ByDecisionID',
        {
            Decision_ID: DecisionID,
        },
        (res) => {
            vueData.detailDecision = res.data[0][0]
            vueData.detailStudent = res.data[1].map((item, index) => {
                return {
                    ...item,
                    SoThuTu: index + 1,
                }
            })
            vueData.FileList = res.data[2]
        },
        (error) => {
            Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
            console.log('get detail decision error: ', error)
        },
    )
}
function htmlToPdf(DecisionID, DecisionType) {
    let url
    if (DecisionType === 'Cao Học') {
        console.log('DecisionType', DecisionType)
        url = `https://qldetaisdh.lhu.edu.vn/rpt_dcsn_msthesis?Decision_ID=${DecisionID}`
    } else if (DecisionType === 'NCS') {
        url = `https://qldetaisdh.lhu.edu.vn/rpt_dcsn_phdthesis?Decision_ID=${DecisionID}`
    } else {
        console.log('Decision type không hợp lệ', DecisionType)
    }
    const newTab = window.open(url, '_blank')
    console.log('Print ID, Type', DecisionID, DecisionType)
    newTab.focus()
}
function onEditData(DecisionID) {
    console.log('Edit decision id', DecisionID)
    ajaxCALL(
        '/Decision_Get_ByDecisionID',
        {
            Decision_ID: DecisionID,
        },
        (res) => {
            vueData.detailDecision = res.data[0][0]
            vueData.detailStudent = res.data[1].map((item, index) => {
                return {
                    ...item,
                    SoThuTu: index + 1,
                }
            })
            vueData.FileList = res.data[2]
            vueData.isEdit = true
        },
        (error) => {
            Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
            console.log('get detail decision error: ', error)
        },
    )
    // vueData.EditData = { ...item }
}
function getDecision() {
    ajaxCALL(
        '/Decision_Get_ByStatus',
        {
            Decision_Status: 0,
        },
        (res) => {
            // Sắp xếp: những phần tử có DecisionFile_Url === null lên đầu
            const sortedData = res.data.sort((a, b) => {
                return (a.DecisionFile_Url === null ? -1 : 1) - (b.DecisionFile_Url === null ? -1 : 1)
            })
            // Gán lại stt sau khi sắp xếp
            vueData.decisionArr = sortedData.map((item, index) => {
                return {
                    ...item,
                    stt: index + 1,
                }
            })
        },
        (error) => {
            Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
            console.log('Get decision status error: ', error)
        },
    )
}
function getHeDaoTao() {
    ajaxCALL(
        '/hedaotao_get',
        null,
        (res) => {
            vueData.heDaoTao = res.data
            console.log('He dao tao', vueData.heDaoTao)
        },
        (error) => {
            Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
            console.log('Get he dao tao fail', error)
        },
    )
}
function getHeByID() {
    // ajaxCALL(
    //     '/Nganh_Get_ByHeID',
    //     {
    //         HeID: heID,
    //     },
    //     (res) => {
    //         vueData.heArr = res.data.map((item) => ({ ...item, Nganh_ID: parseInt(item.Nganh_ID) }))
    //         vueData.heAddArr = res.data
    //         console.log('Get he by ID', vueData.heArr)
    //         console.log('vueData.heAddArr', vueData.heAddArr)
    //     },
    //     (error) => {
    //         Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
    //         console.log('Fail to get he dao tao', error)
    //     },
    // )
    const $this = this
    $.ajax({
        type: 'GET',
        headers: {
            authorization: $awt,
        },
        url: `https://tapi.lhu.edu.vn/hoso/AUTH/Public_SelectNganh_CaoHoc`,
        contentType: 'application/json; charset=utf-8',
        dataType: 'json',
        crossDomain: true,
        success: function (res) {
            // const allListObj = {
            //     NganhID: '0',
            //     TenNganh: '- Tất cả -',
            // }
            vueData.heAddArr = res.data.map((item, index, array) => {
                // Kiểm tra trùng lặp tên ngành (không phân biệt hoa/thường)
                const isDuplicate = array.some((el, i) => i !== index && el.TenNganh.toLowerCase() === item.TenNganh.toLowerCase())
                // Nếu trùng thì gắn thêm KhoaID
                const rawName = isDuplicate ? `${item.TenNganh} (${item.KhoaID})` : item.TenNganh
                // Gộp xử lý removeHocHam vào chung 1 vòng map
                return {
                    ...item,
                    TenNganh: removeHocHam(rawName),
                }
            })
            // vueData.heAddArr.unshift(allListObj)
        },
        error: function (xhr, ajaxOptions, thrownError) {
            $.dialog({
                icon: 'fas fa-exclamation',
                title: 'Error',
                content: xhr.responseJSON ? xhr.responseJSON.Message : xhr.responseText ? xhr.responseText : '',
                type: 'red',
                columnClass: 'col-xs-6 col-xs-offset-6 col-sm-8 col-sm-offset-8 col-md-5 col-md-offset-8',
                closeIcon: true,
                buttons: {
                    ok: {
                        text: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Close&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;',
                        btnClass: 'btn-blue',
                    },
                },
            })
        },
    })
}
function onPrintInTable(item) {
    console.log('print...', item.Decision_ID, item.Decision_Type)
    htmlToPdf(item.Decision_ID, item.Decision_Type)
}
function onPrintWordetail(decisionID) {
    if (decisionID === '' || decisionID === null || decisionID === undefined) {
        Vue.$toast.error(`${'error happen'}`, { position: 'top' })
        return
    }
    let decisionDataQD
    let decisionDataDeTai
    let callGetDetail = () =>
        new Promise((reslove, reject) => {
            ajaxCALL(
                '/Decision_Get_ByDecisionID',
                {
                    Decision_ID: decisionID,
                },
                (res) => {
                    decisionDataQD = res.data[0][0]
                    decisionDataDeTai = res.data[1]
                    let danhsachs = decisionDataDeTai
                        .map((item) => {
                            return {
                                STT: item.STT,
                                MSHV: item.Student_ID,
                                Ho: item.Ho_SV,
                                Ten: item.Ten_SV,
                                HoVaTen: item.Ho_SV + ' ' + item.Ten_SV,
                                NgaySinh: item.Ngay_Sinh,
                                NoiSinh: item.Noi_Sinh,
                                TenDeTai: item.Thesis_Name,
                                GVHD1: item.Thesises_Prof1,
                                GVHD2: item.Thesises_Prof2,
                            }
                        })
                        .sort((a, b) => a.Ten.localeCompare(b.Ten))
                    console.log('lop id', decisionDataDeTai)
                    let model = {
                        NganhInTable: decisionDataQD.Decision_Nganh,
                        Khoa: decisionDataQD.Decision_NienKhoa
                            ? decisionDataQD.Decision_NienKhoa.slice(0, decisionDataQD.Decision_NienKhoa.length - 3) +
                            (decisionDataQD.Decision_Dot === '' || decisionDataQD.Decision_Dot === null ? '' : '.' + decisionDataQD.Decision_Dot)
                            : '',
                        So: decisionDataQD.Decision_MaSo,
                        Ngay: decisionDataQD.Decision_NgayQD,
                        Thang: decisionDataQD.Decision_ThangQD,
                        Nam: decisionDataQD.Decision_NamQD,
                        DanhSach: danhsachs.map((item, index) => {
                            return {
                                ...item,
                                STT: (index + 1).toString(),
                            }
                        }),
                    }
                    reslove(model)
                },
                (error) => {
                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                    console.log('get detail decision error xxx: ', error)
                    reject(error)
                },
            )
        })
    callGetDetail().then((model) => {
        const myHeaders = new Headers()
        myHeaders.append('Content-Type', 'application/json')
        const requestOptions = {
            method: 'POST',
            headers: myHeaders,
            body: JSON.stringify(model),
            redirect: 'follow',
        }
        let spaceChar = decisionDataQD.Decision_SoQD.charCodeAt(0)
        if (
            decisionDataQD.Decision_SoQD !== null &&
            decisionDataQD.Decision_NgayQD !== null &&
            decisionDataQD.Decision_ThangQD !== null &&
            decisionDataQD.Decision_NamQD !== null &&
            decisionDataQD.Decision_NienKhoa !== null &&
            decisionDataQD.Decision_Dot !== null &&
            decisionDataQD.Decision_Nganh !== null &&
            decisionDataQD.Decision_SLHVBangSo !== null &&
            decisionDataQD.Decision_SLHVBangChu !== null &&
            ((decisionDataQD.Decision_MaSo !== null) !== decisionDataQD.Decision_NguoiTao) !== null
        ) {
            if (decisionDataDeTai.length > 0) {
                // https://gendocx.iotsoftvn.com
                // http://localhost:5244
                fetch('https://gendocx.iotsoftvn.com/api/generate-docx/quyet-dinh-detail', requestOptions)
                    .then((response) => response.blob())
                    .then((blob) => {
                        var url = window.URL.createObjectURL(blob)
                        var a = document.createElement('a')
                        a.href = url
                        a.download = spaceChar === 32 ? 'QuyetDinhGiaoDeTai.docx' : `${decisionDataQD.Decision_SoQD} QuyetDinhGiaoDeTai.docx`
                        document.body.appendChild(a) // we need to append the element to the dom -> otherwise it will not work in firefox
                        a.click()
                        a.remove() //afterwards we remove the element again
                    })
                    .catch((error) => console.error(error))
            } else {
                Vue.$toast.error(`Không có danh sách đề tài`, { position: 'top' })
            }
        } else {
            Vue.$toast.error(`Một số trường dữ liệu bị null`, { position: 'top' })
        }
    })
}
function onPrintWordTest(decisionID) {
    if (decisionID === '' || decisionID === null || decisionID === undefined) {
        Vue.$toast.error(`${'error happen'}`, { position: 'top' })
        return
    }
    let decisionDataQD
    let decisionDataDeTai
    let callGetDetail = () =>
        new Promise((reslove, reject) => {
            ajaxCALL(
                '/Decision_Get_ByDecisionID',
                {
                    Decision_ID: decisionID,
                },
                (res) => {
                    decisionDataQD = res.data[0][0]
                    decisionDataDeTai = res.data[1]
                    let danhsachs = decisionDataDeTai.map((item) => {
                        return {
                            STT: item.STT.toString(),
                            MSHV: item.Student_ID,
                            Ho: item.Ho_SV,
                            Ten: item.Ten_SV,
                            HoVaTen: item.Ho_SV + ' ' + item.Ten_SV,
                            NgaySinh: item.Ngay_Sinh,
                            NoiSinh: item.Noi_Sinh,
                            TenDeTai: item.Thesis_Name,
                            GVHD1: item.Thesises_Prof1,
                            GVHD2: item.Thesises_Prof2,
                        }
                    })
                    console.log('lop id', decisionDataDeTai)
                    let model = {
                        SoQuyetDinh: decisionDataQD.Decision_SoQD,
                        Ngay: decisionDataQD.Decision_NgayQD,
                        Thang: decisionDataQD.Decision_ThangQD,
                        Nam: decisionDataQD.Decision_NamQD,
                        Khoa: decisionDataQD.Decision_NienKhoa
                            ? decisionDataQD.Decision_NienKhoa.slice(0, decisionDataQD.Decision_NienKhoa.length - 3) +
                            (decisionDataQD.Decision_Dot === '' || decisionDataQD.Decision_Dot === null ? '' : '.' + decisionDataQD.Decision_Dot)
                            : '',
                        Dot: decisionDataQD.Decision_Dot,
                        Nganh: decisionDataQD.Decision_Nganh,
                        SoLuongSo: decisionDataQD.Decision_SLHVBangSo.toString(),
                        SoLuongChu: decisionDataQD.Decision_SLHVBangChu,
                        MaSo: decisionDataQD.Decision_MaSo,
                        LuuVT: decisionDataQD.Decision_NguoiTao.toString(),
                        NganhID: decisionDataQD.Decision_NganhID ?? 0,
                        Lop: decisionDataDeTai.length > 0 ? decisionDataDeTai[0].Lop_ID : '',
                        DanhSach: danhsachs,
                    }
                    reslove(model)
                },
                (error) => {
                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                    console.log('get detail decision error xxx: ', error)
                    reject(error)
                },
            )
        })
    callGetDetail().then((model) => {
        const myHeaders = new Headers()
        myHeaders.append('Content-Type', 'application/json')
        const requestOptions = {
            method: 'POST',
            headers: myHeaders,
            body: JSON.stringify(model),
            redirect: 'follow',
        }
        let spaceChar = decisionDataQD.Decision_SoQD.charCodeAt(0)
        if (
            decisionDataQD.Decision_SoQD !== null &&
            decisionDataQD.Decision_NgayQD !== null &&
            decisionDataQD.Decision_ThangQD !== null &&
            decisionDataQD.Decision_NamQD !== null &&
            decisionDataQD.Decision_NienKhoa !== null &&
            decisionDataQD.Decision_Dot !== null &&
            decisionDataQD.Decision_Nganh !== null &&
            decisionDataQD.Decision_SLHVBangSo !== null &&
            decisionDataQD.Decision_SLHVBangChu !== null &&
            ((decisionDataQD.Decision_MaSo !== null) !== decisionDataQD.Decision_NguoiTao) !== null
        ) {
            if (decisionDataDeTai.length > 0) {
                //https://gendocx.iotsoftvn.com
                fetch('https://gendocx.iotsoftvn.com/api/generate-docx/quyet-dinh-zip', requestOptions)
                    .then((response) => response.blob())
                    .then((blob) => {
                        var url = window.URL.createObjectURL(blob)
                        var a = document.createElement('a')
                        a.href = url
                        a.download = spaceChar === 32 ? 'QuyetDinhGiaoDeTai.zip' : `${decisionDataQD.Decision_SoQD} QuyetDinhGiaoDeTai.zip`
                        document.body.appendChild(a) // we need to append the element to the dom -> otherwise it will not work in firefox
                        a.click()
                        a.remove() //afterwards we remove the element again
                    })
                    .catch((error) => console.error(error))
            } else {
                Vue.$toast.error(`Không có danh sách đề tài`, { position: 'top' })
            }
        } else {
            Vue.$toast.error(`Một số trường dữ liệu bị null`, { position: 'top' })
        }
    })
    // callGetDetail().then((model) => {
    //     ajaxCALL('https://f37b-115-76-48-90.ngrok-free.app/api/generate-docx', model, (resWord) => {
    //         console.log("call success")
    //         console.log(resWord)
    //     }, (errorWord) => {
    //         // Vue.$toast.error(`${errorWord.responseJSON.Message}`, { position: 'top' });
    //         console.log("call api word fail: ", errorWord)
    //     })
    // })
}
function getMaNganh(nganhId) {
    return vueData.NganhGlobal.find(item => item.NganhID == nganhId).MaNganh ?? ""
}
function onPrintWord(decisionID) {
    if (decisionID === '' || decisionID === null || decisionID === undefined) {
        Vue.$toast.error(`${'error happen'}`, { position: 'top' })
        return
    }
    let decisionDataQD
    let decisionDataDeTai
    let callGetDetail = () =>
        new Promise((resolve, reject) => {
            ajaxCALL(
                '/Decision_Get_ByDecisionID',
                {
                    Decision_ID: decisionID,
                },
                (res) => {
                    decisionDataQD = res.data[0][0]
                    decisionDataDeTai = res.data[1]
                    let danhsachs = decisionDataDeTai
                        .map((item) => ({
                            STT: item.STT,
                            MSHV: item.Student_ID,
                            Ho: item.Ho_SV,
                            Ten: item.Ten_SV,
                            HoVaTen: item.Ho_SV + ' ' + item.Ten_SV,
                            NgaySinh: item.Ngay_Sinh,
                            NoiSinh: item.Noi_Sinh,
                            TenDeTai: item.Thesis_Name,
                            GVHD1: item.Thesises_Prof1,
                            GVHD2: item.Thesises_Prof2,
                            NoiCongTacGVHD1: item.CoQuanCongTac_GVHD1 ? item.CoQuanCongTac_GVHD1.trim() : "",
                            NoiCongTacGVHD2: item.CoQuanCongTac_GVHD2 ? item.CoQuanCongTac_GVHD2.trim() : "",
                            EmailGVHD1: item.Email_GVHD1 ? item.Email_GVHD1.trim() : "",
                            EmailGVHD2: item.Email_GVHD2 ? item.Email_GVHD2.trim() : "",
                            SoDienThoaiGVHD1: item.SoDT_GVHD1 ? item.SoDT_GVHD1.trim() : "",
                            SoDienThoaiGVHD2: item.SoDT_GVHD2 ? item.SoDT_GVHD2.trim() : "",
                        }))
                        .sort((a, b) => a.Ten.localeCompare(b.Ten))
                    let model = {
                        SoQuyetDinh: decisionDataQD.Decision_SoQD,
                        Ngay: decisionDataQD.Decision_NgayQD,
                        Thang: decisionDataQD.Decision_ThangQD,
                        Nam: decisionDataQD.Decision_NamQD,
                        Nganh: decisionDataQD.Decision_Nganh,
                        NganhID: decisionDataQD.Decision_NganhID ?? 0,
                        MaNganh: getMaNganh(decisionDataQD.Decision_NganhID),
                        ProcessID: decisionDataDeTai.length > 0 ? decisionDataDeTai[0].Process_ID : 0,
                        Dot: decisionDataQD.Decision_Dot,
                        Khoa: decisionDataQD.Decision_NienKhoa
                            ? decisionDataQD.Decision_NienKhoa.slice(0, decisionDataQD.Decision_NienKhoa.length - 3) +
                            (decisionDataQD.Decision_Dot === '' || decisionDataQD.Decision_Dot === null ? '' : '.' + decisionDataQD.Decision_Dot)
                            : '',
                        SoHocVien: danhsachs.length.toString(),
                        SoHocVienBangChu: numberToText(danhsachs.length),
                        MaSo: decisionDataQD.Decision_MaSo,
                        LuuVT: decisionDataQD.Decision_NguoiTao.toString(),
                        Lop: decisionDataDeTai.length > 0 ? decisionDataDeTai[0].Lop_ID : '',
                        DanhSach: danhsachs.map((item, index) => {
                            return {
                                ...item,
                                STT: (index + 1).toString(),
                            }
                        }),
                    }
                    let modelChiTiet = {
                        NganhInTable: decisionDataQD.Decision_Nganh.toUpperCase(),
                        Khoa: decisionDataQD.Decision_NienKhoa
                            ? decisionDataQD.Decision_NienKhoa.slice(0, decisionDataQD.Decision_NienKhoa.length - 3) +
                            (decisionDataQD.Decision_Dot === '' || decisionDataQD.Decision_Dot === null ? '' : '.' + decisionDataQD.Decision_Dot)
                            : '',
                        SoQuyetDinh: decisionDataQD.Decision_SoQD,
                        NganhID: decisionDataQD.Decision_NganhID ?? 0,
                        ProcessID: decisionDataDeTai.length > 0 ? decisionDataDeTai[0].Process_ID : 0,
                        Lop: decisionDataDeTai.length > 0 ? decisionDataDeTai[0].Lop_ID : '',
                        Ngay: decisionDataQD.Decision_NgayQD,
                        Thang: decisionDataQD.Decision_ThangQD,
                        Nam: decisionDataQD.Decision_NamQD,
                        DanhSach: danhsachs.map((item, index) => {
                            return {
                                ...item,
                                STT: (index + 1).toString(),
                            }
                        }),
                    }
                    resolve({ model, modelChiTiet })
                },
                (error) => {
                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                    reject(error)
                },
            )
        })
    callGetDetail().then(({ model, modelChiTiet }) => {
        const myHeaders = new Headers()
        myHeaders.append('Content-Type', 'application/json')
        const requestOptions = {
            method: 'POST',
            headers: myHeaders,
            body: JSON.stringify(model),
        }
        const requestChiTiet = {
            method: 'POST',
            headers: myHeaders,
            body: JSON.stringify(modelChiTiet),
        }
        let zip = new JSZip()
        let spaceChar = decisionDataQD.Decision_SoQD.charCodeAt(0)
        // https://gendocx.iotsoftvn.com
        // http://localhost:5244
        const domain = 'https://gendocx.iotsoftvn.com'
        Promise.all([
            fetch(`${domain}/api/generate-docx/quyet-dinh-tong-quat`, requestOptions).then((res) => res.blob()),
            fetch(`${domain}/api/generate-docx/quyet-dinh-detail`, requestChiTiet).then((res) => res.blob()),
        ])
            .then(([blob1, blob2]) => {
                zip.file('QuyetDinh.docx', blob1)
                zip.file('DanhSachChiTiet.docx', blob2)
                return zip.generateAsync({ type: 'blob' })
            })
            .then((content) => {
                let a = document.createElement('a')
                a.href = URL.createObjectURL(content)
                a.download = spaceChar === 32 ? 'QuyetDinhGiaoDeTai.zip' : `${decisionDataQD.Decision_SoQD} QuyetDinhGiaoDeTai.zip`
                a.click()
            })
            .catch((error) => {
                console.error(error)
                Vue.$toast.error('Lỗi khi tải file zip', { position: 'top' })
            })
    })
}