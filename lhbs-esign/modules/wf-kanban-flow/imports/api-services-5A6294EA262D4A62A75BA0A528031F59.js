// API Service cho Kanban Workflow Management
// Sử dụng apiCallAsync global từ hệ thống

const WorkflowKanbanAPI = {
    // Lấy danh sách quy trình để chọn
    getWorkflows: async function () {
        try {
            const data = await apiCallAsync('WF_Definition_GetList', { Status: 'ACTIVE' })
            const arr = Array.isArray(data) ? data : (data.data ? (Array.isArray(data.data) ? data.data : []) : [])
            return arr.map(function (w) {
                return { value: w.DefinitionID, title: w.Name || w.DefinitionName || w.Code }
            })
        } catch (err) {
            console.error('Load workflows error:', err)
            return []
        }
    },
 
    // Lấy danh sách trạng thái/cột từ instance hiện tại
    getColumns: async function (definitionID) {
        try {
            if (!definitionID) return []
            const data = await apiCallAsync('WF_Definition_GetDetail', { DefinitionID: definitionID })
            if (!data) return []

            const steps = data.Steps || data.steps || []
            const colors = ['#FF8A9B', '#FFD93D', '#6BCB77', '#4D96FF', '#FF6B6B', '#9B59B6', '#3498DB']

            const result = steps.filter(function (s) {
                return s.StepType !== 'START' && s.StepType !== 'END'
            }).map(function (step, index) {
                return {
                    id: step.StepOrder || step.StepCode || index,
                    tenCot: step.StepName,
                    mau: colors[index % colors.length],
                    stepOrder: step.StepOrder || 0
                }
            })
            result.sort(function (a, b) { return a.stepOrder - b.stepOrder })
            return result
        } catch (err) {
            console.error('Load columns error:', err)
            if (showToast && showToast.error) {
                showToast.error('Lỗi tải danh sách bước')
            }
            return []
        }
    },

    // Lấy danh sách tasks/instances từ dashboard
    getTasks: async function (definitionID) {
        try {
            if (!definitionID) return []
            const data = await apiCallAsync('WF_Instance_GetList', { Filter: 'ALL' })
            if (!data) return []

            const dataArray = Array.isArray(data) ? data : (data.data ? (Array.isArray(data.data) ? data.data : []) : [])
            const filtered = dataArray.filter(function (item) {
                return String(item.DefinitionID) === String(definitionID)
            })

            return filtered.map(function (item) {
                return {
                    id: item.InstanceID || item.DraftID || item.id,
                    cotId: item.CurrentStepName || 'Chưa nhận hồ sơ',
                    tieuDe: item.InstanceName || item.DraftName || item.title || '',
                    moTa: item.DefinitionName || '',
                    uuTien: item.Status === 'WAITING_ME' ? 'cao' : 'trung_binh',
                    hanChot: item.UpdateTime || item.CreateTime || '',
                    nguoiPhuTrach: item.AssigneeName || item.CreateUser || '',
                    tags: item.Status ? [item.Status] : [],
                    danhSachNguoiLienQuan: [],
                    tenQuyTrinh: item.DefinitionName || '',
                    trangThaiQuyTrinh: item.Status || 'RUNNING',
                    buocHienTai: 1,
                    danhSachGhiChu: [],
                    danhSachLichSu: [],
                    ngayTao: item.CreateTime || '',
                    ngayCapNhatCuoi: item.UpdateTime || '',
                    InstanceID: item.InstanceID || null,
                    Status: item.Status || ''
                }
            })
        } catch (err) {
            console.error('Load tasks error:', err)
            if (showToast && showToast.error) {
                showToast.error('Lỗi tải danh sách tasks')
            }
            return []
        }
    },

    // Lấy chi tiết một task
    getTaskDetail: async function (instanceID) {
        try {
            const data = await apiCallAsync('WF_Instance_GetDetail', { InstanceID: instanceID })
            if (!data) return null
            const item = Array.isArray(data) ? data[0] : data
            if (!item) return null
            return {
                id: item.InstanceID || item.id,
                cotId: item.CurrentStatusID || item.statusId || 1,
                tieuDe: item.InstanceName || item.title || '',
                moTa: item.Description || item.description || '',
                uuTien: item.Priority || 'trung_binh',
                hanChot: item.DueDate || item.dueDate || '',
                nguoiPhuTrach: item.AssignedTo || item.assignee || '',
                tags: item.Tags ? (typeof item.Tags === 'string' ? item.Tags.split(',').map(function (t) { return t.trim() }) : item.Tags) : [],
                danhSachNguoiLienQuan: item.Stakeholders ? (typeof item.Stakeholders === 'string' ? item.Stakeholders.split(',').map(function (t) { return t.trim() }) : item.Stakeholders) : [],
                tenQuyTrinh: item.WorkflowName || '',
                trangThaiQuyTrinh: item.WorkflowStatus || 'Đang thực hiện',
                buocHienTai: item.CurrentStepNo || 1,
                danhSachGhiChu: item.Comments ? (Array.isArray(item.Comments) ? item.Comments : []) : [],
                danhSachLichSu: item.History ? (Array.isArray(item.History) ? item.History : []) : [],
                ngayTao: item.CreatedDate || item.createdAt || '',
                ngayCapNhatCuoi: item.UpdatedDate || item.updatedAt || ''
            }
        } catch (err) {
            console.error('Load task detail error:', err)
            if (showToast && showToast.error) {
                showToast.error('Lỗi tải chi tiết task')
            }
            return null
        }
    },

    // Tạo task mới
    createTask: async function (payload) {
        try {
            const response = await apiCallAsync('WF_Instance_Create', {
                DefinitionID: payload.workflowDefinitionID || 1,
                InstanceName: payload.tieuDe,
                Description: payload.moTa || '',
                CurrentStatusID: payload.cotId || 1,
                Priority: payload.uuTien || 'trung_binh',
                DueDate: payload.hanChot || '',
                AssignedTo: payload.nguoiPhuTrach || '',
                Tags: Array.isArray(payload.tags) ? payload.tags.join(',') : '',
                Stakeholders: Array.isArray(payload.danhSachNguoiLienQuan) ? payload.danhSachNguoiLienQuan.join(',') : ''
            })
            if (showToast && showToast.success) {
                showToast.success('Tạo task thành công')
            }
            return response || {}
        } catch (err) {
            console.error('Create task error:', err)
            if (showToast && showToast.error) {
                showToast.error('Lỗi tạo task')
            }
            throw err
        }
    },

    // Cập nhật task
    updateTask: async function (payload) {
        try {
            const response = await apiCallAsync('WF_Instance_Update', {
                InstanceID: payload.id,
                InstanceName: payload.tieuDe,
                Description: payload.moTa || '',
                CurrentStatusID: payload.cotId || 1,
                Priority: payload.uuTien || 'trung_binh',
                DueDate: payload.hanChot || '',
                AssignedTo: payload.nguoiPhuTrach || '',
                Tags: Array.isArray(payload.tags) ? payload.tags.join(',') : '',
                Stakeholders: Array.isArray(payload.danhSachNguoiLienQuan) ? payload.danhSachNguoiLienQuan.join(',') : ''
            })
            if (showToast && showToast.success) {
                showToast.success('Cập nhật task thành công')
            }
            return response || {}
        } catch (err) {
            console.error('Update task error:', err)
            if (showToast && showToast.error) {
                showToast.error('Lỗi cập nhật task')
            }
            throw err
        }
    },

    // Xóa task
    deleteTask: async function (instanceID) {
        try {
            const response = await apiCallAsync('WF_Instance_Delete', { InstanceID: instanceID })
            if (showToast && showToast.success) {
                showToast.success('Xóa task thành công')
            }
            return response || {}
        } catch (err) {
            console.error('Delete task error:', err)
            if (showToast && showToast.error) {
                showToast.error('Lỗi xóa task')
            }
            throw err
        }
    },

    // Cập nhật trạng thái task
    updateTaskStatus: async function (instanceID, statusID) {
        try {
            const response = await apiCallAsync('WF_Instance_UpdateStatus', {
                InstanceID: instanceID,
                StatusID: statusID
            })
            return response || {}
        } catch (err) {
            console.error('Update task status error:', err)
            if (showToast && showToast.error) {
                showToast.error('Lỗi cập nhật trạng thái')
            }
            throw err
        }
    },

    // Thêm ghi chú/bình luận
    addComment: async function (instanceID, content, author) {
        try {
            const response = await apiCallAsync('WF_Instance_AddComment', {
                InstanceID: instanceID,
                Content: content,
                Author: author
            })
            if (showToast && showToast.success) {
                showToast.success('Thêm ghi chú thành công')
            }
            return response || {}
        } catch (err) {
            console.error('Add comment error:', err)
            if (showToast && showToast.error) {
                showToast.error('Lỗi thêm ghi chú')
            }
            throw err
        }
    }
}

// Export để sử dụng trong components
if (typeof window !== 'undefined') {
    window.WorkflowKanbanAPI = WorkflowKanbanAPI
}
