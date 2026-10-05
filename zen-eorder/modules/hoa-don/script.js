function getOrder() {
    if (vueData.CuaHangID) {
        const params = { CuaHangID: vueData.CuaHangID }
        ajaxCALL("/eorder/HoaDon_Select_ByCuaHangId", params, (res) => {
            if (res.data) {
                vueData.DSHoaDon = res.data
                //Xử lý replace những data thay đổi
                vueData.DSHoaDon.forEach((item) => {
                    const index = vueData.DSHoaDon_Res.findIndex((res) => res.HoaDonID === item.HoaDonID)
                    if (index >= 0) {
                        if (vueData.DSHoaDon_Res[index].ThoiGianCapNhat !== item.ThoiGianCapNhat) {
                            vueData.DSHoaDon_Res.splice(index, 1)
                            vueData.DSHoaDon_Res.push(item)
                        }
                    } else {
                        vueData.DSHoaDon_Res.push(item)
                    }
                })
                //Filter hóa đơn -> 2: Chờ thanh toán, 9: Đang tiếp nhận
                vueData.DSHoaDonDaTiepNhan = res.data.filter((item) => item.TrangThai === 9 || item.TrangThai === 2)
                //Xử lý replace những data thay đổi
                vueData.DSHoaDonDaTiepNhan.forEach((item) => {
                    const index = vueData.DSHoaDonDaTiepNhan_Res.findIndex((res) => res.HoaDonID === item.HoaDonID)
                    if (index >= 0) {
                        if (vueData.DSHoaDonDaTiepNhan_Res[index].ThoiGianCapNhat !== item.ThoiGianCapNhat || vueData.DSHoaDonDaTiepNhan_Res[index].TongMonChuaTra !== item.TongMonChuaTra) {
                            vueData.DSHoaDonDaTiepNhan_Res.splice(index, 1)
                            vueData.DSHoaDonDaTiepNhan_Res.push(item)
                        }
                    } else {
                        vueData.DSHoaDonDaTiepNhan_Res.push(item)
                    }
                })
                //Xóa những data không có trong DB
                vueData.DSHoaDonDaTiepNhan_Res.forEach((item, index) => {
                    const findIndex = vueData.DSHoaDonDaTiepNhan.findIndex((res) => res.HoaDonID === item.HoaDonID)
                    if (findIndex < 0) {
                        vueData.DSHoaDonDaTiepNhan_Res.splice(index, 1)
                    }
                })
                vueData.DSHoaDonDaTiepNhan_ResFilter = vueData.DSHoaDonDaTiepNhan_Res
                //Set lại chi tiết hóa đơn nếu đang mở Dialog xem chi tiết
                if (vueData.CTHoaDon && vueData.CTHoaDon.HoaDonID > 0) {
                    const filterOrder = vueData.DSHoaDonDaTiepNhan_ResFilter.filter((item) => item.HoaDonID === vueData.CTHoaDon.HoaDonID)
                    vueData.CTHoaDon = filterOrder[0]
                }
            }
        })
    }
    //Load chi tiết hóa đơn nếu đang xem chi tiết
    if (vueData.CTHoaDon?.HoaDonID > 0) {
        const params = { HoaDonID: vueData.CTHoaDon.HoaDonID }
        ajaxCALL("/eorder/HoaDonChiTiet_Select_ByHoaDonId", params, (res) => {
            if (res.data) {
                vueData.DSChiTietHoaDon = res.data
            }
        })
    }
}
const intervalLoad = setInterval(getOrder, 60000) //Tự động Load lại 1 phút / lần
onCancelOrder = () => {
    if (vueData.CTHoaDon) {
        const content = vueData.CTHoaDon?.GrabOrderID ? `Bạn có chắc muốn hủy hóa đơn ${vueData.CTHoaDon?.MaSoHoaDon}, Thao tác này sẽ ảnh hưởng tới đơn GRAB?` : `Bạn có chắc muốn hủy hóa đơn ${vueData.CTHoaDon?.MaSoHoaDon}?`
        confirm({
            title: content,
            action: () => {
                const $this = this
                if (vueData.CTHoaDon?.GrabOrderID != null) $this.handleCancelOrderGrab()
                else $this.handleCancelOrder()
            },
        })
    }
}
function handleCancelOrder() {
    const optionCancel = vueData.OptionsCancelOrder.find((c) => c.value == vueData.cancelCodeGRAB)
    const cancelText = optionCancel?.text ?? null
    const params = {
        HoaDonID: vueData.CTHoaDon.HoaDonID,
        GhiChu_Huy: cancelText ?? vueData.CTHoaDon?.GhiChu_Huy,
        IsThayThe: 0,
    }
    ajaxCALL("/eorder/HoaDon_Huy", params, (res) => {
        if (res.data) {
            showMessage({
                type: "green",
                title: "Hủy hóa đơn thành công",
                icon: "fa fa-check-circle",
            })
            vueData.IsShowDialogDetail = false
            const indexOrder = vueData.DSHoaDon_Res.findIndex((res) => res.HoaDonID === vueData.CTHoaDon.HoaDonID)
            vueData.DSHoaDon_Res.splice(indexOrder, 1) //Remove
            const index = vueData.DSHoaDonDaTiepNhan_Res.findIndex((res) => res.HoaDonID === vueData.CTHoaDon.HoaDonID)
            vueData.DSHoaDonDaTiepNhan_Res.splice(index, 1) //Remove
            vueData.cancelCodeGRAB = null
        }
    })
}
function handleCancelOrderGrab() {
    const merchantID = vueData.DSCuaHang.find((ch) => ch.CuaHangID == vueData.CuaHangID)?.MerchantID
    if (!merchantID) return
    const params = {
        orderID: vueData.CTHoaDon.GrabOrderID,
        merchantID: merchantID,
        cancelCode: vueData.cancelCodeGRAB,
    }
    ajaxCALL("/eorder/GRABPUSH_Order_Cancel", { Json_Data: JSON.stringify(params) }, (res) => {
        if (res.httpErrorCode == 403)
            return showMessage({
                type: "red",
                title: "Không thể hủy đơn",
                message: "Bạn đã đạt giới hạn hủy đơn của cửa hàng trên GRAB trong hôm nay!",
            })
        this.handleCancelOrder()
    })
}
function onSaveOrder() {
    if (vueData.CTHoaDon) {
        confirm({
            title: `Cập nhật thông tin hóa đơn`,
            content: `Bạn có chắc muốn nhật thông tin hóa đơn ${vueData.CTHoaDon?.MaSoHoaDon}?`,
            action: function () {
                const params = {
                    HoaDonID: vueData.CTHoaDon.HoaDonID,
                    KhachTra_TienMat: checkNumber(vueData.CTHoaDon.KhachTra_TienMat) ? vueData.CTHoaDon.KhachTra_TienMat : 0,
                    KhachTra_CK: checkNumber(vueData.CTHoaDon.KhachTra_CK) ? vueData.CTHoaDon.KhachTra_CK : 0,
                    KhachTra_SPF: checkNumber(vueData.CTHoaDon.KhachTra_SPF) ? vueData.CTHoaDon.KhachTra_SPF : 0,
                    KhachTra_XSM: checkNumber(vueData.CTHoaDon.KhachTra_XSM) ? vueData.CTHoaDon.KhachTra_XSM : 0,
                    KhachTra_GRAB: checkNumber(vueData.CTHoaDon.KhachTra_GRAB) ? vueData.CTHoaDon.KhachTra_GRAB : 0,
                    KhachTra_QT: checkNumber(vueData.CTHoaDon.KhachTra_QT) ? vueData.CTHoaDon.KhachTra_QT : 0,
                    KhachTra_HT1: checkNumber(vueData.CTHoaDon.KhachTra_HT1) ? vueData.CTHoaDon.KhachTra_HT1 : 0,
                    KhachTra_HT2: checkNumber(vueData.CTHoaDon.KhachTra_HT2) ? vueData.CTHoaDon.KhachTra_HT2 : 0,
                    KhachTra_HT3: checkNumber(vueData.CTHoaDon.KhachTra_HT3) ? vueData.CTHoaDon.KhachTra_HT3 : 0,
                }
                ajaxCALL("/eorder/HoaDon_Update_HinhThucThanhToan", params, (res) => {
                    if (res.data) {
                        vueData.IsShowDialogDetail = false
                        showMessage({
                            type: "green",
                            title: "Cập nhật thông tin hóa đơn thành công",
                            icon: "fa fa-check-circle",
                        })
                    }
                })
            },
        })
    }
}
function onPrintOrder() {
    if (vueData.CTHoaDon) {
        const params = {
            HoaDonID: vueData.CTHoaDon.HoaDonID,
            GhiChu: vueData.CTHoaDon.GhiChu,
            LoaiIn: 2, //In hóa đơn
        }
        ajaxCALL("/eorder/HoaDon_In", params, (res) => {
            if (res.data) {
                Vue.$toast.success("In thành công", { position: "top" })
            }
        })
    }
}
function onPrintTem(data) {
    const formData = data.data
    if (formData.HoaDonChiTietID > 0) {
        const params = {
            HoaDonID: formData.HoaDonID,
            SanPhamGUID: formData.SanPhamGUID,
        }
        ajaxCALL("/eorder/HoaDonChiTiet_InTem", params, (res) => {
            if (res.data) {
                Vue.$toast.success("In tem thành công", { position: "top" })
            }
        })
    }
}
function redirectToPos(item) {
    const detail = item.data
    window.location.href = `/pos?chid=${detail.CuaHangID}&hdid=${detail.HoaDonID}`
}
function onOpenDetailTable(item) {
    const detail = item.data
    const params = { HoaDonID: detail.HoaDonID }
    ajaxCALL("/eorder/HoaDonChiTiet_Select_ByHoaDonId", params, (res) => {
        if (res.data) {
            vueData.CTHoaDon = detail
            vueData.DSChiTietHoaDon = res.data
            vueData.IsShowDialogDetail = true
        }
    })
}
function onOpenDetailBank(item) {
    const params = {
        HoaDonID: item.data.HoaDonID,
    }
    ajaxCALL("/eorder/HoaDon_Bank_Select_ByHoaDonId", params, (res) => {
        if (res.data) {
            vueData.CTHoaDon = item.data
            vueData.CTBank = res.data[0]
            vueData.IsShowDialogBankDetail = true
        }
    })
}
function shorten(str, max = 12) {
    return str.length > max ? str.slice(0, max) + "..." : str
}
function sendMail(item) {
    const { HoaDonID } = item?.data
    if (!HoaDonID) return
    ajaxCALL("/eorder/EINVOICE_SendMail", { HoaDonID: HoaDonID }, (Response) => {
        if (Response.data) {
            Vue.$toast.success("Gửi mail thành công", { position: "top" })
            vueData.eInvoiceRefresh = !vueData.eInvoiceRefresh
        }
    })
}
function createInvoice(item) {
    const { HoaDonID } = item?.data
    if (!HoaDonID) return
    ajaxCALL("/eorder/EINVOICE_CreateInvoice", { HoaDonID: HoaDonID }, (Response) => {
        if (Response.data) {
            Vue.$toast.success("Đã phát hành hóa đơn điện tử", {
                position: "top",
            })
            vueData.eInvoiceRefresh = !vueData.eInvoiceRefresh
        }
    })
}
function getDetailInvoice(item) {
    vueData.isShowModalDetailInvoice = true
    vueData.detailInvoice = { ...item.data }
}
function getDetailInvoiceReplace(item) {
    vueData.isShowModalDetailInvoiceReplace = true
    vueData.detailInvoice = { ...item.data }
    const fileList = {
        Files: [
            {
                FileID: item.data?.FileID,
                FileName: item.data?.FileName,
                ContentType: item.data?.ContentType,
                FileSize: item.data?.Size,
            },
        ],
    }
    vueData.fileUpload = fileList
}
function closeDetailInvoice() {
    vueData.isShowModalDetailInvoice = false
    vueData.detailInvoice = {}
}
function saveDetailInvoice(isExport = 0) {
    ajaxCALL("/eorder/HoaDonDienTu_Update", { ...vueData.detailInvoice, Is_Release: isExport }, (res) => {
        if (res.data) {
            Vue.$toast.success("Cập nhật thông tin hóa đơn thành công", {
                position: "top",
            })
            vueData.isShowModalDetailInvoice = false
            vueData.eInvoiceRefresh = !vueData.eInvoiceRefresh
            vueData.detailInvoice = {}
        }
    })
}
function saveInvoiceReplace() {
    const params = {
        HoaDonID: vueData.detailInvoice.HoaDonID,
        ThayThe_LyDo: vueData.detailInvoice.XuLy_LyDoThayThe,
        ThayThe_FileID: vueData.fileUpload.Files[0]?.FileID,
        Invoice_BuyerTaxCode: vueData.detailInvoice.XuLy_MaSoThue,
        Invoice_BuyerLegalName: vueData.detailInvoice.XuLy_TenKhachHang,
        Invoice_BuyerAddressLine: vueData.detailInvoice.XuLy_DiaChi,
        Invoice_BuyerPhoneNumber: vueData.detailInvoice.XuLy_SoDienThoai,
        Invoice_BuyerEmail: vueData.detailInvoice.XuLy_Email,
        Invoice_ResultInvoiceNo: vueData.detailInvoice.XuLy_SoHoaDonThayThe,
    }
    ajaxCALL("/eorder/HoaDonDienTu_Update_ThayThe", params, (res) => {
        if (res.data) {
            Vue.$toast.success("Cập nhật thông tin hóa đơn thay thế thành công", {
                position: "top",
            })
            vueData.isShowModalDetailInvoiceReplace = false
            vueData.detailInvoice = {}
            vueData.eInvoiceRefresh = !vueData.eInvoiceRefresh
        }
    })
}
function getPrintInvoice(item) {
    ajaxCALL("/eorder/HoaDon_Select_ById", { HoaDonID: item.data.HoaDonID }, async (res) => {
        if (res.data) {
            await handleDataInvoice(res.data)
        } else {
            Vue.$toast.error("Không tìm thấy hóa đơn để in", { position: "top" })
        }
    })
}
async function convertImageUrlToBase64(url) {
    const response = await fetch(url)
    const blob = await response.blob()
    return await new Promise((resolve, reject) => {
        const reader = new FileReader()
        reader.onloadend = () => resolve(reader.result)
        reader.onerror = reject
        reader.readAsDataURL(blob)
    })
        .then((base64) => {
            return base64
        })
        .catch((err) => {})
}
async function handleDataInvoice(data) {
    const dataHoaDon = data[0][0]
    const dataSanPham = data[1]
    const base64Logo = await convertImageUrlToBase64(dataHoaDon.LogoURL)
    //Xử lý danh sách sản phẩm
    let tableSanPham = []
    tableSanPham.push([
        { text: "#", style: "headerTable", alignment: "center" },
        { text: "Tên món", style: "headerTable", alignment: "center" },
        { text: "SL", style: "headerTable", alignment: "center" },
        { text: "ĐG", style: "headerTable", alignment: "center" },
        { text: "TT", style: "headerTable", alignment: "center" },
    ])
    let products = dataSanPham.filter((item) => item.Is_SanPham == 1)
    let toppings = dataSanPham.filter((item) => item.Is_SanPham == 0)
    products.forEach((item, index) => {
        let toppingsByItem = toppings.filter((tp) => tp.SanPhamGUID == item.SanPhamGUID)
        let groupItem = [
            [
                {
                    text: index + 1,
                    style: "textCellStyle",
                    border: [true, true, true, toppingsByItem.length > 0 ? false : true],
                },
                {
                    text: item.TenHienThi,
                    style: "textCellStyle",
                    border: [true, true, true, toppingsByItem.length > 0 ? false : true],
                },
                {
                    text: formatPrice(item.SoLuong),
                    style: "textCellStyle",
                    alignment: "right",
                    border: [false, true, true, toppingsByItem.length > 0 ? false : true],
                },
                {
                    text: formatPrice(item.DonGia),
                    style: "textCellStyle",
                    alignment: "right",
                    border: [false, true, true, toppingsByItem.length > 0 ? false : true],
                },
                {
                    text: formatPrice(item.ThanhTien),
                    style: "textCellStyle",
                    alignment: "right",
                    border: [false, true, true, toppingsByItem.length > 0 ? false : true],
                },
            ],
        ]
        toppingsByItem.forEach((tp, indextp) => {
            // groupItem[0][1].text += '\n+ ' + tp.TenHienThi
            groupItem.push([
                {
                    text: "",
                    style: "textCellStyle",
                    border: [true, false, true, indextp == toppingsByItem.length - 1 && index == products.length - 1 ? true : false],
                },
                {
                    text: "+ " + tp.TenHienThi,
                    style: "textCellStyle",
                    border: [true, false, true, indextp == toppingsByItem.length - 1 && index == products.length - 1 ? true : false],
                },
                {
                    text: formatPrice(tp.SoLuong),
                    style: "textCellStyle",
                    alignment: "right",
                    border: [false, false, true, indextp == toppingsByItem.length - 1 && index == products.length - 1 ? true : false],
                },
                {
                    text: formatPrice(tp.DonGia),
                    style: "textCellStyle",
                    alignment: "right",
                    border: [false, false, true, indextp == toppingsByItem.length - 1 && index == products.length - 1 ? true : false],
                },
                {
                    text: formatPrice(tp.ThanhTien),
                    style: "textCellStyle",
                    alignment: "right",
                    border: [false, false, true, indextp == toppingsByItem.length - 1 && index == products.length - 1 ? true : false],
                },
            ])
        })
        groupItem.forEach((item1) => {
            tableSanPham.push(item1)
        })
    })
    // Khởi tạo File PDF
    const docDefinition = {
        pageSize: {
            width: 198, // tương đương 80mm
            height: "auto", // hoặc số cụ thể nếu muốn cố định chiều cao
        },
        pageMargins: [5, 5], // lề trái, trên, phải, dưới (tùy chỉnh được)
        content: [
            {
                image: base64Logo,
                width: 80,
                alignment: "center",
            },
            {
                text: `${dataHoaDon.TenCuaHang ?? "-"}`,
                style: "tenCuaHang",
                alignment: "center",
            },
            {
                text: `MST: ${dataHoaDon.Invoice_SellerTaxCode ?? "-"}`,
                style: "textSmallStyle",
                alignment: "center",
            },
            {
                text: `${dataHoaDon.DiaChi.replace(/<br\s*\/?>/gi, "\n") ?? "-"}`,
                style: "textSmallStyle",
                alignment: "center",
            },
            {
                text: "HÓA ĐƠN THANH TOÁN",
                style: "hoaDonThanhToan",
                alignment: "center",
            },
            {
                text: `Số: ${dataHoaDon.MaHoaDon ?? "-"}`,
                style: "textSmallBoldStyle",
                alignment: "center",
            },
            {
                margin: [0, 2],
                text: [
                    { text: "Ngày: ", style: "labelStyle", alignment: "left" },
                    {
                        text: `${dataHoaDon.NgayThemMoi ?? "-"}`,
                        style: "textCellStyle",
                        alignment: "left",
                    },
                ],
            },
            {
                margin: [0, 2],
                text: [
                    { text: "Bàn: ", style: "labelStyle", alignment: "left" },
                    {
                        text: `${dataHoaDon.TenBan ?? "-"}`,
                        style: "textCellStyle",
                        alignment: "left",
                    },
                ],
            },
            {
                margin: [0, 2],
                text: [
                    { text: "Thu ngân: ", style: "labelStyle", alignment: "left" },
                    {
                        text: `${dataHoaDon.NhanVienThanhToan ?? "-"}`,
                        style: "textCellStyle",
                        alignment: "left",
                    },
                ],
            },
            {
                margin: [0, 2],
                text: [
                    { text: "Khách hàng: ", style: "labelStyle", alignment: "left" },
                    {
                        text: `${dataHoaDon.KhachHang_HoTen ?? "-"}`,
                        style: "textCellStyle",
                        alignment: "left",
                    },
                ],
            },
            {
                margin: [0, 2],
                text: [
                    { text: "Ghi chú: ", style: "labelStyle", alignment: "left" },
                    {
                        text: `${dataHoaDon.GhiChu ?? "-"}`,
                        style: "textCellStyle",
                        alignment: "left",
                    },
                ],
            },
            {
                layout: {
                    hLineWidth: function (i, node) {
                        return i === 0 || i === node.table.body.length ? 0.5 : 0.5
                    },
                    vLineWidth: function (i, node) {
                        return i === 0 || i === node.table.widths.length ? 0.5 : 0.5
                    },
                    hLineColor: function (i, node) {
                        return i === 0 || i === node.table.body.length ? "black" : "gray"
                    },
                    vLineColor: function (i, node) {
                        return i === 0 || i === node.table.widths.length ? "black" : "gray"
                    },
                },
                table: {
                    widths: ["5%", "*", "auto", "auto", "auto"],
                    body: tableSanPham,
                },
            },
            {
                margin: [0, 5, 0, 0],
                widths: ["50%", "50%"],
                columns: [
                    { text: "Tiền hàng:", style: "labelStyle", alignment: "left" },
                    {
                        text: `${formatPrice(dataHoaDon.TienPhaiTra) ?? "-"}đ`,
                        style: "textContentStyle",
                        alignment: "right",
                    },
                ],
            },
            {
                margin: [0, 5, 0, 0],
                widths: ["50%", "50%"],
                columns: [
                    {
                        text: `Thuế GTGT (${dataHoaDon.PhanTramVAT}%):`,
                        style: "labelStyle",
                        alignment: "left",
                    },
                    {
                        text: `${formatPrice(dataHoaDon.TongVAT) ?? "-"}đ`,
                        style: "textContentStyle",
                        alignment: "right",
                    },
                ],
            },
            {
                margin: [0, 5, 0, 0],
                widths: ["50%", "50%"],
                columns: [
                    { text: "Tổng thanh toán:", style: "labelStyle", alignment: "left" },
                    {
                        text: `${formatPrice(dataHoaDon.TongTien) ?? "-"}đ`,
                        style: "textContentStyle",
                        alignment: "right",
                    },
                ],
            },
            {
                canvas: [
                    {
                        type: "line",
                        x1: 0,
                        y1: 5,
                        x2: 188,
                        y2: 5,
                        lineWidth: 0.6,
                        dash: { length: 3, space: 2 }, // hoặc { length: 2, space: 2 } để tùy chỉnh
                    },
                ],
                margin: [0, 0, 0, 0], // tùy chỉnh khoảng cách trên dưới
            },
            detechHinhThucThanhToan(dataHoaDon),
            {
                margin: [0, 5, 0, 0],
                widths: ["50%", "50%"],
                columns: [
                    { text: "Trả lại khách:", style: "labelStyle", alignment: "left" },
                    {
                        text: `${formatPrice(dataHoaDon.TienThua) ?? "-"}đ`,
                        style: "textContentStyle",
                        alignment: "right",
                    },
                ],
            },
            {
                canvas: [
                    {
                        type: "line",
                        x1: 0,
                        y1: 5,
                        x2: 188,
                        y2: 5,
                        lineWidth: 0.6,
                        dash: { length: 3, space: 2 }, // hoặc { length: 2, space: 2 } để tùy chỉnh
                    },
                ],
                margin: [0, 0, 0, 0], // tùy chỉnh khoảng cách trên dưới
            },
            {
                text: "Trân trọng cảm ơn!",
                style: "header",
                alignment: "center",
                margin: [0, 5, 0, 0],
            },
            {
                canvas: [
                    {
                        type: "line",
                        x1: 0,
                        y1: 5,
                        x2: 188,
                        y2: 5,
                        lineWidth: 0.6,
                        dash: { length: 3, space: 2 }, // hoặc { length: 2, space: 2 } để tùy chỉnh
                    },
                ],
                margin: [0, 0, 0, 0], // tùy chỉnh khoảng cách trên dưới
            },
            {
                text: "THÔNG TIN HÓA ĐƠN ĐIỆN TỬ",
                style: "header",
                alignment: "center",
            },
            {
                margin: [0, 2],
                text: [
                    { text: "Tên công ty: ", style: "labelStyle", alignment: "left" },
                    {
                        text: `${dataHoaDon.Invoice_BuyerLegalName ?? "-"}`,
                        style: "textCellStyle",
                        alignment: "left",
                    },
                ],
            },
            {
                margin: [0, 2],
                text: [
                    { text: "Mã số thuế: ", style: "labelStyle", alignment: "left" },
                    {
                        text: `${dataHoaDon.Invoice_BuyerTaxCode ?? "-"}`,
                        style: "textCellStyle",
                        alignment: "left",
                    },
                ],
            },
            {
                margin: [0, 2],
                text: [
                    { text: "Địa chỉ: ", style: "labelStyle", alignment: "left" },
                    {
                        text: `${dataHoaDon.Invoice_BuyerAddressLine ?? "-"}`,
                        style: "textCellStyle",
                        alignment: "left",
                    },
                ],
            },
            {
                margin: [0, 2],
                text: [
                    { text: "Ký hiệu: ", style: "labelStyle", alignment: "left" },
                    {
                        text: `${dataHoaDon.Invoice_InvoiceSeries ?? "-"}`,
                        style: "textCellStyle",
                        alignment: "left",
                    },
                ],
            },
            {
                margin: [0, 2],
                text: [
                    { text: "Số hóa đơn: ", style: "labelStyle", alignment: "left" },
                    {
                        text: `${dataHoaDon.Invoice_ResultInvoiceNo ?? "Chưa có"}`,
                        style: "textCellStyle",
                        alignment: "left",
                    },
                ],
            },
            {
                margin: [0, 2],
                text: [
                    { text: "Mã CQT: ", style: "labelStyle", alignment: "left" },
                    {
                        text: `${dataHoaDon.Invoice_CQT ?? "-"}`,
                        style: "textCellStyle",
                        alignment: "left",
                    },
                ],
            },
            {
                margin: [0, 2],
                text: [
                    { text: "Mã tra cứu: ", style: "labelStyle", alignment: "left" },
                    {
                        text: `${dataHoaDon.Invoice_ResultReservationCode ?? "-"}`,
                        style: "textCellStyle",
                        alignment: "left",
                    },
                ],
            },
            {
                margin: [0, 2],
                text: [
                    { text: "Tra cứu tại: ", style: "labelStyle", alignment: "left" },
                    {
                        text: `https://sinvoice.viettel.vn/tracuuhoadon`,
                        style: "textCellStyle",
                        alignment: "left",
                    },
                ],
            },
            {
                margin: [0, 2],
                text: [
                    { text: "Lưu ý: ", style: "labelStyle", alignment: "left" },
                    {
                        text: "Đây là hoá đơn điện tử khởi tạo từ máy tính tiền theo nghị định số 123/2020/NĐ-CP. Anh/Chị có thể sử dụng thông tin trên để hạch toán, kê khai thuế",
                        style: "textCellStyle",
                        italics: true,
                    },
                ],
            },
        ],
        images: {
            imagelogo: base64Logo,
        },
        styles: {
            header: {
                fontSize: 10,
                bold: true,
                margin: [0, 5, 0, 5],
            },
            tenCuaHang: {
                fontSize: 10,
                bold: true,
            },
            hoaDonThanhToan: {
                fontSize: 10,
                bold: true,
                margin: [0, 3, 0, 0],
            },
            labelStyle: {
                fontSize: 8,
                bold: true,
                margin: [0, 0, 0, 0],
            },
            textContentStyle: {
                fontSize: 8,
                bold: false,
                margin: [0, 0, 0, 0],
            },
            textSmallStyle: {
                fontSize: 8,
                bold: false,
            },
            textSmallBoldStyle: {
                fontSize: 8,
                bold: true,
                margin: [0, 0, 0, 3],
            },
            textCellStyle: {
                fontSize: 8,
            },
            headerTable: {
                fontSize: 9,
                bold: true,
            },
        },
        defaultStyle: {
            alignment: "justify",
        },
    }
    vueData.isShowModalPrintInvoice = true
    //Generator PDF
    const pdfDocGenerator = pdfMake.createPdf(docDefinition)
    //View PDF in iframe
    pdfDocGenerator.getDataUrl((dataUrl) => {
        const targetElement = document.querySelector("#iframeContainer")
        targetElement.innerHTML = ""
        const iframe = document.createElement("iframe")
        iframe.src = dataUrl
        targetElement.appendChild(iframe)
    })
}
function detechHinhThucThanhToan(dataHoaDon) {
    const arrayHinhThucThanhToan = [
        { raw: "KhachTra_CK", title: "Chuyển khoản" },
        { raw: "KhachTra_GRAB", title: "GRAB" },
        { raw: "KhachTra_SPF", title: "Shopee food" },
        { raw: "KhachTra_XSM", title: "Xanh SM" },
        { raw: "KhachTra_TienMat", title: "Tiền mặt" },
        { raw: "KhachTra_QT", title: "Quẹt thẻ" },
        { raw: "KhachTra_HT1", title: "HT1" },
        { raw: "KhachTra_HT2", title: "HT2" },
        { raw: "KhachTra_HT3", title: "HT3" },
    ]
    let fieldMoney = []
    arrayHinhThucThanhToan.forEach((ht) => {
        if (dataHoaDon[ht.raw] == 0) return
        let obj = {
            margin: [0, 5, 0, 0],
            widths: ["50%", "50%"],
            columns: [
                { text: `${ht.title}:`, style: "labelStyle", alignment: "left" },
                {
                    text: `${formatPrice(dataHoaDon[ht.raw]) ?? "0"}đ`,
                    style: "textContentStyle",
                    alignment: "right",
                },
            ],
        }
        fieldMoney.push(obj)
    })
    return fieldMoney
}
function closeModalPrintInvoice() {
    vueData.isShowModalPrintInvoice = false
    vueData.dataPDF = {}
}