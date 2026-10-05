function getRowClass(item) {
    if (["Voucher Nhận", "Voucher Quét", "Voucher Đổi"].includes(item.ThuocTinh))  return 'highlight-total';
}