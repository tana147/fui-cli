function htnlToPdf(item) {
    let url;
    url = `https://qldetaisdh.lhu.edu.vn/rpt_teacher_invite?GVHD=${item.GVHD}&TimeSelect=${item.ThoiGian}`
    const newTab = window.open(url, '_blank');
    newTab.focus();
}