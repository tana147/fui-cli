const ajaxCALLPromise = (url, params = null) => {
    return new Promise(resolve => {
        ajaxCALL(url, params, res => resolve(res.data))
    })
}
vueData.ajaxCALLPromise = ajaxCALLPromise