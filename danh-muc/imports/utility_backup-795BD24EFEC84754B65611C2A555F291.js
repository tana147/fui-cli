// function apiCall(url, params, onSuccess, onError) {
//     loadingPage.show()
//     $.ajax({
//         type: 'POST',
//         headers: { authorization: $awt },
//         url: vueData.v_Set.apiDomain + url,
//         contentType: 'application/json; charset=utf-8',
//         dataType: 'json',
//         crossDomain: true,
//         data: JSON.stringify(params),
//         success: function (d) {
//             if (onSuccess) onSuccess(d)
//         },
//         error: function (xhr) {
//             console.error('API:', url, '', params, '', xhr)
//             if (onError) {
//                 onError(xhr)
//                 return
//             }
//             showToast.error(`Đã có lỗi xảy ra: ${xhr.responseJSON ? xhr.responseJSON.Message : xhr.responseText ? xhr.responseText : ''}`)
//         },
//         complete: function (xhr, status) {
//             loadingPage.hide()
//         },
//     })
// }

// function apiCallNoLoading(url, params, onSuccess, onError) {
//     $.ajax({
//         type: 'POST',
//         headers: { authorization: $awt },
//         url: vueData.v_Set.apiDomain + url,
//         contentType: 'application/json; charset=utf-8',
//         dataType: 'json',
//         crossDomain: true,
//         data: JSON.stringify(params),
//         success: function (d) {
//             if (onSuccess) onSuccess(d)
//         },
//         error: function (xhr) {
//             console.error('API:', url, '', params, '', xhr)
//             if (onError) {
//                 onError(xhr)
//                 return
//             }
//             showToast.error(`Đã có lỗi xảy ra: ${xhr.responseJSON ? xhr.responseJSON.Message : xhr.responseText ? xhr.responseText : ''}`)
//         },
//     })
// }

// const loadingPage = {
//     show: () => {
//         vueData.v_Set.isLoading = true
//     },
//     hide: () => {
//         vueData.v_Set.isLoading = false
//     },
// }

// const showToast = {
//     success: (text) => {
//         Vue.$toast.success(text, { position: 'top-right', duration: 2000 })
//     },
//     error: (text) => {
//         Vue.$toast.error(text, { position: 'top-right', duration: 10000 })
//     },
//     info: (text) => {
//         Vue.$toast.info(text, { position: 'top-right', duration: 2000 })
//     },
// }

// function showConfirm(text, onOk, onCancel) {
//     $.confirm({
//         title: 'Thông báo',
//         content: text ? text : '',
//         type: 'blue',
//         animateFromElement: false,
//         buttons: {
//             cancel: {
//                 text: '<i class="v-icon v-icon--size-default mdi mdi-close mr-1"></i> Hủy',
//                 btnClass: 'v-btn bg-grey-lighten-2 v-btn--density-default v-btn--size-default v-btn--variant-flat',
//                 action: onCancel ? onCancel : function () { },
//             },
//             ok: {
//                 text: '<i class="v-icon v-icon--size-default mdi mdi-check-circle mr-1"></i> Đồng ý',
//                 btnClass: 'v-btn bg-primary v-btn--density-default v-btn--size-default v-btn--variant-flat',
//                 keys: ['enter'],
//                 action: onOk,
//             },
//         },
//     })
// }

// function showAlert(text, onClose) {
//     $.alert({
//         title: 'Thông báo',
//         content: text ? text : '',
//         type: 'blue',
//         animateFromElement: false,
//         buttons: {
//             cancel: {
//                 text: '<i class="v-icon v-icon--size-default mdi mdi-close mr-1"></i> Đóng',
//                 btnClass: 'v-btn bg-grey-lighten-2 v-btn--density-default v-btn--size-default v-btn--variant-flat',
//                 action: onClose ? onClose : function () { },
//             },
//         },
//     })
// }

// function apiCallPromise(url, params = null) {
//     return new Promise((resolve, reject) => {
//         apiCall(url, params, (res) => resolve(res.data))
//     })
// }

// function apiCallPromiseNoLoading(url, params = null) {
//     return new Promise((resolve, reject) => {
//         apiCallNoLoading(url, params, (res) => resolve(res.data))
//     })
// }

// function formatDate(d) {
//     return d ? dayjs(d).format('DD/MM/YYYY') : ''
// }

// function formatTime(date) {
//     return dayjs(date).locale('vi').format('HH:mm - DD/MM')
// }

// function formatDateTime(date) {
//     return dayjs(date).locale('vi').format('HH:mm - DD/MM/YYYY')
// }

// function getTamKhoaIcon(status) {
//     const icons = {
//         true: 'mdi-lock',
//     }
//     return icons[status]
// }

// function getTamKhoaColor(status) {
//     const colors = {
//         true: 'primary',
//     }
//     return colors[status] || 'grey'
// }

// const apiFile = {
//     insertAndUpdate: async (params, options = {}) => {
//         try {
//             // Default options
//             const defaultOptions = {
//                 maxFileSize: 5, // MB
//                 showToast: true,
//                 validateFileSize: true,
//             }

//             // Merge options
//             const config = { ...defaultOptions, ...options }

//             if (!params) {
//                 console.warn('Thiếu Params')
//                 if (config.showToast) showToast.error('Thiếu tham số params')
//                 return {
//                     isSuccess: false,
//                     message: 'Thiếu tham số params',
//                     data: null,
//                 }
//             }
//             if (params?.List_FileID === null || params?.List_FileID === undefined) {
//                 console.warn('Params thiếu trường List_FileID')
//                 if (config.showToast) showToast.error('Params thiếu trường List_FileID')
//                 return {
//                     isSuccess: false,
//                     message: 'Params thiếu trường List_FileID',
//                     data: null,
//                 }
//             }
//             if (!params?.file) {
//                 console.warn('Params thiếu trường file')
//                 if (config.showToast) showToast.error('Params thiếu trường file')
//                 return {
//                     isSuccess: false,
//                     message: 'Params thiếu trường file',
//                     data: null,
//                 }
//             }

//             // Validate kích thước file nếu được bật
//             if (config.validateFileSize) {
//                 const maxSize = config.maxFileSize * 1024 * 1024 // Convert MB to bytes
//                 for (var file of params.file) {
//                     if (file.size > maxSize) {
//                         const fileSizeMB = (file.size / (1024 * 1024)).toFixed(2)
//                         const errorMsg = `File "${file.name}" có kích thước ${fileSizeMB}MB, vượt quá giới hạn ${config.maxFileSize}MB`
//                         console.warn(errorMsg)
//                         if (config.showToast) showToast.error(errorMsg)
//                         return {
//                             isSuccess: false,
//                             message: errorMsg,
//                             data: null,
//                         }
//                     }
//                 }
//             }

//             const uploadFile = async (file, FileID) => {
//                 try {
//                     const formData = new FormData()
//                     formData.append('file', file)
//                     const headers = new Headers()
//                     headers.append('Authorization', $awt)
//                     headers.append(
//                         'uploaddata',
//                         JSON.stringify([
//                             {
//                                 FileID: FileID || '',
//                             },
//                         ]),
//                     )

//                     const response = await fetch('https://file.zentea.vn/work/upload/HH_FileData', {
//                         method: 'POST',
//                         headers: headers,
//                         body: formData,
//                     })

//                     if (!response.ok) {
//                         throw new Error(`HTTP error! status: ${response.status}`)
//                     }

//                     const result = await response.json()
//                     return result
//                 } catch (error) {
//                     console.error('Lỗi khi upload file:', error)
//                     if (config.showToast) showToast.error(`Lỗi khi upload file: ${error.message}`)
//                     throw error
//                 }
//             }

//             const result = []

//             const List_FileID = params?.List_FileID?.split(',') || []
//             for (var i = 0; i < params.file.length; i++) {
//                 const file = params.file[i]
//                 const FileID = List_FileID[i] || ''
//                 const data = await uploadFile(file, FileID)
//                 result.push(data)
//             }

//             const newResult = []
//             for (var item of result) {
//                 const x = item.Files[0]
//                 newResult.push(x)
//             }

//             return {
//                 isSuccess: true,
//                 message: 'Upload file thành công',
//                 data: newResult,
//             }
//         } catch (error) {
//             console.error('Lỗi trong api File function:', error)
//             const config = { showToast: true, ...options }
//             if (config.showToast) showToast.error(`Lỗi trong quá trình xử lý: ${error.message}`)
//             return {
//                 isSuccess: false,
//                 message: error.message || 'Lỗi trong quá trình xử lý',
//                 data: null,
//             }
//         }
//     },
//     delete: async (fileId, options = {}) => {
//         try {
//             const defaultOptions = {
//                 showToast: true,
//             }

//             const config = { ...defaultOptions, ...options }

//             // Validate fileId
//             if (!fileId) {
//                 console.warn('Thiếu fileId')
//                 if (config.showToast) showToast.error('Thiếu tham số fileId')
//                 return {
//                     isSuccess: false,
//                     message: 'Thiếu tham số fileId',
//                     data: null,
//                 }
//             }

//             const response = await fetch(vueData.v_Set.apiDomain + 'lms/LMS_FileData_Del_ByFileID', {
//                 method: 'POST',
//                 headers: {
//                     Authorization: $awt,
//                 },
//                 body: JSON.stringify({ FileID: fileId }),
//             })

//             if (!response.ok) {
//                 throw new Error(`HTTP error! status: ${response.status}`)
//             }

//             const responseJS = await response.json()

//             if (responseJS) {
//                 if (config.showToast) showToast.success('Xóa file thành công')
//                 return {
//                     isSuccess: true,
//                     message: 'Xóa file thành công',
//                     data: responseJS,
//                 }
//             }

//             return {
//                 isSuccess: false,
//                 message: 'Không có phản hồi từ server',
//                 data: null,
//             }
//         } catch (error) {
//             console.error('Lỗi khi xóa file:', error)
//             const config = { showToast: true, ...options }
//             if (config.showToast) showToast.error(`Lỗi khi xóa file: ${error.message}`)

//             return {
//                 isSuccess: false,
//                 message: error.message || 'Lỗi trong quá trình xóa file',
//                 data: null,
//             }
//         }
//     },
// }

// function getStatusText(status) {
//     const colors = {
//         NHAP: 'NHÁP',
//         DANG_SU_DUNG: 'ĐANG SỬ DỤNG',
//         NGUNG_SU_DUNG: 'NGƯNG SỬ DỤNG',
//         TEST: 'ĐANG TEST',
//     }
//     return colors[status] || ''
// }

// function getStatusColor(status) {
//     const colors = {
//         NHAP: 'warning',
//         DANG_SU_DUNG: 'success',
//         NGUNG_SU_DUNG: 'error',
//         TEST: 'blue-grey',
//     }
//     return colors[status] || 'grey'
// }
