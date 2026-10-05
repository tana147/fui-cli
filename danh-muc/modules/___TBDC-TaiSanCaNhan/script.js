var token = $cookies.isKey("awt") ? $cookies.get("awt") : null;
axios.defaults.baseURL = 'https://api.zentea.vn/work/';
axios.defaults.headers.common['Authorization'] = token;
axios.defaults.headers.post['Content-Type'] = 'application/json; charset=utf-8';