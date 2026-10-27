function apiCall(url, params, onSuccess, onError) {
    const t0 = performance.now()
    const reqId = Math.random().toString(36).slice(2, 8)

    const S = {
        chip: 'padding:2px 8px;border-radius:99px;font-size:11px;font-weight:700;background:#059669;color:#ffffff',
        method: 'padding:2px 6px;border-radius:4px;font-size:10px;font-weight:700;background:#2563eb;color:#ffffff',
        url: 'color:#b45309;font-size:12px;font-weight:700',
        label: 'color:#6b7280;font-size:11px;font-weight:700',
        ok: 'color:#16a34a;font-size:11px;font-weight:700',
        err: 'color:#dc2626;font-size:11px;font-weight:700',
        ms: 'color:#9ca3af;font-size:11px',
    }

    const flatten = (obj, prefix = '', out = {}) => {
        for (const [k, v] of Object.entries(obj ?? {})) {
            const key = prefix ? `${prefix}.${k}` : k
            if (v && typeof v === 'object' && !Array.isArray(v)) flatten(v, key, out)
            else out[key] = v
        }
        return out
    }

    // Buffer log lại, flush 1 lần khi response về → tránh lồng group khi parallel requests
    const logBuffer = []
    const buf = {
        groupCollapsed: (...a) => logBuffer.push({ fn: 'groupCollapsed', a }),
        log: (...a) => logBuffer.push({ fn: 'log', a }),
        table: (...a) => logBuffer.push({ fn: 'table', a }),
    }

    const flush = () => {
        for (const { fn, a } of logBuffer) console[fn](...a)
        console.groupEnd()
        logBuffer.length = 0
    }

    buf.groupCollapsed(
        '%c API %c %c POST %c %s %c #%s',
        S.chip, '', S.method, S.url, url, S.ms, reqId
    )
    buf.log('%cparams', S.label, flatten(params))

    $.ajax({
        type: 'POST',
        headers: { authorization: $awt },
        url: vueData.v_Set.apiDomain + '/' + url,
        contentType: 'application/json; charset=utf-8',
        dataType: 'json',
        crossDomain: true,
        data: JSON.stringify(params),

        success(res) {
            const ms = (performance.now() - t0).toFixed(1)
            buf.log('%cSUCCESS %c%sms', S.ok, S.ms, ms)

            const data = res?.data ?? res

            const isNestedArray = Array.isArray(data) && data.some(i => Array.isArray(i))

            if (isNestedArray) {
                // Mỗi array con → 1 bảng riêng với label
                data.forEach((group, i) => {
                    buf.log(`%c[${i}] %c${group.length} items`, 'color:#2563eb;font-weight:700', 'color:#9ca3af')
                    if (group.length === 0) {
                        buf.log('%c(empty)', 'color:#9ca3af;font-style:italic')
                    } else if (group.length > 100) {
                        buf.log(group)
                    } else {
                        buf.table(group)
                    }
                })
            } else if (Array.isArray(data) && data.length > 100) {
                buf.log(data)
            } else if (Array.isArray(data)) {
                buf.table(data)
            } else {
                buf.table(flatten(data))
            }

            flush()
            if (onSuccess) onSuccess(res)
        },

        error(xhr) {
            const ms = (performance.now() - t0).toFixed(1)
            const msg =
                xhr.responseJSON?.Message ||
                xhr.responseJSON?.message ||
                xhr.responseJSON?.error ||
                xhr.responseText ||
                `HTTP ${xhr.status}`

            buf.log('%cERROR %c%s · %sms', S.err, S.ms, xhr.status, ms)
            buf.table({ status: xhr.status, message: msg })

            flush()
            if (onError) { onError(xhr); return }
            showToast.error(msg)
        },
    })
}

function apiCallAsync(url, params = null) {
    return new Promise((resolve, reject) => {
        apiCall(url, params, function (res) { resolve(res.data) }, function (xhr) { reject(xhr) })
    })
}

const loadingPage = {
    show: () => {
        vueData.v_Set.isLoading = true
    },
    hide: () => {
        vueData.v_Set.isLoading = false
    },
}

const showToast = {
    success: (text) => createVanillaToast('success', text, 2500),
    error: (text) => createVanillaToast('error', text, 10000),
    info: (text) => createVanillaToast('info', text, 3000),
}

function createVanillaToast(type, content, duration) {
    if (typeof document === 'undefined') return

    // 1. Phân tách tiêu đề và thông điệp (hỗ trợ truyền string hoặc object)
    let title = ''
    let message = ''

    if (content && typeof content === 'object') {
        title = content.title || ''
        message = content.message || ''
    } else {
        message = String(content || '')
        // Tự động sinh tiêu đề mặc định cho giống uc-toast cũ
        const defaultTitles = {
            success: 'Thành công',
            error: 'Lỗi',
            warning: 'Cảnh báo',
            info: 'Thông báo'
        }
        title = defaultTitles[type] || 'Thông báo'
    }

    // 2. Tạo hoặc lấy container dùng chung trên body
    let container = document.querySelector('.uc-toast-container')
    if (!container) {
        container = document.createElement('div')
        container.className = 'uc-toast-container top-right'
        document.body.appendChild(container)
    }

    // 3. Tạo Toast Item mới
    const toastItem = document.createElement('div')
    toastItem.className = 'uc-toast-item'
    // Thêm các class transition enter
    toastItem.style.opacity = '0'
    toastItem.style.transform = 'translateX(100%) scale(0.9)'

    // Định nghĩa icon và màu sắc (chuyển sang Material Design Icons để đồng bộ Vuetify)
    const themes = {
        success: { icon: 'mdi mdi-check-circle', color: '#10b981' },
        error: { icon: 'mdi mdi-close-circle', color: '#ef4444' },
        warning: { icon: 'mdi mdi-alert', color: '#f59e0b' },
        info: { icon: 'mdi mdi-information', color: '#3b82f6' }
    }
    const theme = themes[type] || themes.info
    const activeIcon = (content && content.icon) ? content.icon : theme.icon

    // HTML của Title (nếu có)
    const titleHtml = title ? '<h4 class="uc-toast-title">' + title + '</h4>' : ''

    // 4. Xây dựng nội dung HTML khớp chuẩn CSS toàn cục
    toastItem.innerHTML =
        '<div class="uc-toast-content">' +
        '<div class="uc-toast-icon" style="color: ' + theme.color + '; display: flex; align-items: center; justify-content: center;">' +
        '<i class="' + activeIcon + '" style="font-size: 24px;"></i>' +
        '</div>' +
        '<div class="uc-toast-text">' +
        titleHtml +
        '<div class="uc-toast-message">' + message + '</div>' +
        '</div>' +
        '<button class="uc-toast-close" style="display: flex; align-items: center; justify-content: center;"><i class="mdi mdi-close" style="font-size: 18px;"></i></button>' +
        '</div>' +
        '<div class="uc-toast-progress-bg">' +
        '<div class="uc-toast-progress-bar" style="background-color: ' + theme.color + '; animation-duration: ' + duration + 'ms;"></div>' +
        '</div>'

    container.appendChild(toastItem)

    // Trigger hiệu ứng trượt vào (CSS Transition)
    requestAnimationFrame(function () {
        toastItem.style.transition = 'all 0.4s cubic-bezier(0.4, 0, 0.2, 1)'
        toastItem.style.opacity = '1'
        toastItem.style.transform = 'translateX(0) scale(1)'
    })

    // 5. Logic xóa Toast
    let timer = null
    let startTime = Date.now()
    let remaining = duration

    const removeFn = function () {
        if (timer) clearTimeout(timer)
        // Hiệu ứng trượt biến mất
        toastItem.style.opacity = '0'
        toastItem.style.transform = 'translateX(100%) scale(0.9)'

        setTimeout(function () {
            if (toastItem.parentNode) {
                toastItem.parentNode.removeChild(toastItem)
            }
            // Tự dọn container nếu trống
            if (container.childNodes.length === 0 && container.parentNode) {
                container.parentNode.removeChild(container)
            }
        }, 400)
    }

    // Nút close
    const closeBtn = toastItem.querySelector('.uc-toast-close')
    if (closeBtn) {
        closeBtn.onclick = removeFn
    }

    // 6. Quản lý thời gian tự động tắt & Hover Pause/Resume
    const progressBar = toastItem.querySelector('.uc-toast-progress-bar')

    const startTimer = function () {
        if (duration > 0) {
            timer = setTimeout(removeFn, remaining)
            if (progressBar) progressBar.style.animationPlayState = 'running'
        }
    }

    const pauseTimer = function () {
        if (timer) {
            clearTimeout(timer)
            timer = null
        }
        remaining -= (Date.now() - startTime)
        if (progressBar) progressBar.style.animationPlayState = 'paused'
    }

    const resumeTimer = function () {
        startTime = Date.now()
        startTimer()
    }

    toastItem.onmouseenter = pauseTimer
    toastItem.onmouseleave = resumeTimer

    // Khởi động
    startTimer()
}

function showConfirm(text, onOk, onCancel) {
    $.confirm({
        title: "Thông báo",
        content: text ? text : "",
        type: "blue",
        animateFromElement: false,
        buttons: {
            cancel: {
                text: '<i class="v-icon v-icon--size-default mdi mdi-close mr-1"></i> Hủy',
                btnClass: "wf-confirm-btn wf-confirm-btn--cancel",
                action: onCancel ? onCancel : function () { },
            },
            ok: {
                text: '<i class="v-icon v-icon--size-default mdi mdi-check-circle mr-1"></i> Đồng ý',
                btnClass: "wf-confirm-btn wf-confirm-btn--ok",
                keys: ["enter"],
                action: onOk,
            },
        },
    })
}

function showAlert(title, text, onClose) {
    $.alert({
        title: title,
        content: text ? text : "",
        type: "blue",
        animateFromElement: false,
        buttons: {
            cancel: {
                text: '<i class="v-icon v-icon--size-default mdi mdi-close mr-1"></i> Đóng',
                btnClass: "v-btn bg-grey-lighten-2 v-btn--density-default v-btn--size-default v-btn--variant-flat",
                action: onClose ? onClose : function () { },
            },
        },
    })
}


function ajaxCALL_File(URL, formData, callBack, errorCallBack, header) {
    let loadingID = generateID();
    app.config.globalProperties.v_LoadingOverlay.push(loadingID);
    app.config.globalProperties.v_Loading = true;

    $.ajax({
        type: "POST",
        headers: (header ? header : {
            authorization: $awt
        }),
        url: fixURL(URL),
        processData: false,
        contentType: false,
        crossDomain: true,
        data: formData,
        success: function (d) {
            json_data_parse(d, 0);
            if (callBack) callBack(d);
        },
        error: function (xhr, ajaxOptions, thrownError) {
            console.log("API:", URL, "IN:", formData);
            console.log("Error XHR:", xhr);

            if (errorCallBack) {
                errorCallBack(xhr);
                return
            }

            showMessage({
                icon: 'mdi mdi-alert-circle-outline',
                title: '',
                message: (xhr.responseJSON ? xhr.responseJSON.Message : (xhr.responseText ? xhr.responseText : "")),
                type: 'red',
            });
        },
        complete: function (data) {
            app.config.globalProperties.v_LoadingOverlay = _.without(app.config.globalProperties.v_LoadingOverlay, loadingID);
            if (app.config.globalProperties.v_LoadingOverlay.length == 0) app.config.globalProperties.v_Loading = false;
        }
    });
}
