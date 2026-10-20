function selectDeTai(deTai) {
    vueData.studentSelectedArr.push(deTai)
    resetSTT()
}
function resetSTT() {
    vueData.studentSelectedArr.forEach((item, index) => {
        item.STT = index + 1; // Reset STT từ 1 trở đi
    });
}
function deleteSelectDeTai(stt) {
    let findDeTai = vueData.studentSelectedArr.findIndex(item => item.STT === stt)
    console.log("findDeTai", findDeTai)
    if (findDeTai !== -1) {
        vueData.studentSelectedArr.splice(findDeTai, 1);
        resetSTT()
    }
}