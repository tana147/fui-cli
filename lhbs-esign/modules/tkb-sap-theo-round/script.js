// FIX (2026-09-15, theo phan anh nguoi dung — Round 1.5 da giai xong that su tren server
// (TrangThai=Feasible, ThoiGianKetThuc da ghi), nhung UI van dung yen hien "Dang chay... 27 phut").
// Nguyen nhan: cac Round dai (1.5/1.6/2/4) dung window.setInterval(6000ms) de poll trang thai —
// khi tab trinh duyet chay NEN (nguoi dung chuyen qua tab/app khac) qua lau, trinh duyet tu dong
// THROTTLE setInterval (co the delay toi vai phut/lan, hoac dung han) de tiet kiem pin/CPU. Ket qua
// that su da xong tu lau nhung UI khong bao gio duoc hoi lai de biet.
// Sua: dang ky lang nghe 'visibilitychange' + 'focus' — moi lan tab duoc focus/hien lai (nguoi dung
// quay lai xem), NEU dang co 1 round dang poll (vueData.dangPoll khac rong) thi CHECK LAI NGAY LAP
// TUC bang chinh action kiemTra tuong ung, khong doi setInterval tu bat kip. Dam bao du interval bi
// throttle bao nhieu, chi can nguoi dung quay lai tab la thay dung trang thai ngay.
var _tkbVisibilityRecheckArmed = false;
function tkbRecheckDangPoll() {
    if (!vueData || !vueData.dangPoll) return;
    if (vueData.dangPoll === 'round1_5') CALL(vueData.kiemTraRound1_5);
    else if (vueData.dangPoll === 'round1_6') CALL(vueData.kiemTraRound1_6);
    else if (vueData.dangPoll === 'round2') CALL(vueData.kiemTraRound2);
    else if (vueData.dangPoll === 'round4') CALL(vueData.kiemTraRound4);
}
function tkbSetupVisibilityRecheck() {
    if (_tkbVisibilityRecheckArmed) return;
    _tkbVisibilityRecheckArmed = true;
    document.addEventListener('visibilitychange', function () {
        if (document.visibilityState === 'visible') tkbRecheckDangPoll();
    });
    window.addEventListener('focus', tkbRecheckDangPoll);
}