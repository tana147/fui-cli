var token = $cookies.isKey("awt") ? $cookies.get("awt") : null;
axios.defaults.baseURL = 'https://api.zentea.vn/work/';
axios.interceptors.request.use(function (config) {
    if (config.url && !config.url.startsWith('https') && !config.url.startsWith('TS_')) {
        config.url = 'TS_' + config.url;
    }
    return config;
}, function (error) {
    return Promise.reject(error);
});
axios.defaults.headers.common['Authorization'] = token;
axios.defaults.headers.post['Content-Type'] = 'application/json; charset=utf-8';
// config vuetify
vuetifyDefaultSetting.defaults.VToolbar.color = "white"
//config for base TBDC, remove soon