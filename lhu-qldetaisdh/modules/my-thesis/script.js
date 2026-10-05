function checkTopicBtn(TenDeTai) {
    ajaxCALL("/Get_SimiliarPaper", {
        "TenDeTai": TenDeTai
    }, (res) => {
        vueData.similiarTopic = res.data
        vueData.similiarList = res.data
    }, (error) => {
        Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
        console.log("Error: ", error)
    })
}