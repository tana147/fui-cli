function getRowClass(item) {
    if (["Voucher Nhận", "Voucher Quét", "Voucher Đổi", "Voucher Tặng"].includes(item.ThuocTinh))  return 'highlight-total';
}