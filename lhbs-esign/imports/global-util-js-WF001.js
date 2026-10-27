function ajaxCALLPromise(url, params = null) {
    return new Promise((resolve) => {
        ajaxCALL(
            url,
            params,
            (res) => resolve(res.data),
            (error) => {
                console.error("CALL Error:", error);
                const errMsg = error && error.responseJSON && error.responseJSON.Message
                    ? error.responseJSON.Message
                    : "Lỗi thực hiện tác vụ";
                if (typeof Vue !== "undefined" && Vue.$toast) {
                    Vue.$toast.error(errMsg, { position: "top" });
                }
                resolve(null);
            }
        );
    });
}

function ajaxGETCALLPromise(url, params = null) {
    return new Promise((resolve) => {
        const headers = {
            "Content-Type": "application/json; charset=utf-8"
        };
        if (typeof $awt !== "undefined" && $awt) {
            headers["Authorization"] = $awt;
        }
        $.ajax({
            url: url,
            type: "GET",
            data: params,
            headers: headers,
            success: (res) => resolve(res),
            error: (err) => {
                console.error("GET Error:", err);
                const errMsg = err.responseJSON && err.responseJSON.Message
                    ? err.responseJSON.Message
                    : "Lỗi kết nối máy chủ";
                if (typeof Vue !== "undefined" && Vue.$toast) {
                    Vue.$toast.error(errMsg, { position: "top" });
                }
                resolve(null);
            }
        });
    });
}

