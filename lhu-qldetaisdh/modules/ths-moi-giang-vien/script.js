function htnlToPdf(item) {
    let url;
    url = `https://qldetaisdh.lhu.edu.vn/ths-in-thu-moi-giang-vien?GVHD=${item.GVHD}&TimeSelect=${item.ThoiGian}`
    const newTab = window.open(url, '_blank');
    newTab.focus();
}