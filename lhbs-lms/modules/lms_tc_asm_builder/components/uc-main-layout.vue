<template>
	<Global>
        <uc-assignment-builder v-if="dataReady" :initial-assignment="assignment" :is-edit-mode="isEditMode"
            :on-save="saveAssignment" :on-auto-save="autoSaveAssignment" />
        <div v-else-if="errorMessage" class="d-flex justify-center align-center fill-height pa-8" style="min-height: 400px;">
            <v-card max-width="500" class="pa-6 text-center" variant="outlined">
                <v-icon color="error" size="48" class="mb-3">mdi-alert-circle-outline</v-icon>
                <div class="text-h6 font-weight-bold mb-2">{{ IsEngLish ? 'Unable to load assignment' : 'Không thể tải bài tập' }}</div>
                <div class="text-body-2 text-medium-emphasis mb-4">{{ formatErrorMessage(errorMessage) }}</div>
                <v-btn color="primary" variant="elevated" @click="retryInit">{{ IsEngLish ? 'Retry' : 'Thử lại' }}</v-btn>
            </v-card>
        </div>
        <div v-else class="d-flex justify-center align-center fill-height pa-8" style="min-height: 400px;">
            <v-progress-circular indeterminate color="primary" size="48" />
        </div>
    </Global>
</template>

<script>
	export default {
		inject: ['snackbarRef', 'iframeRef', 'confirmRef'],
  data() {
    return {
      dataReady: false,
      isEditMode: false,
      assignment: null,
      errorMessage: '',
    }
  },
  created() {
    this.syncLocale()
  },
  computed: {
    IsEngLish() {
      if (this.$i18n?.locale === 'en') return true
      try {
        const isLang = JSON.parse(localStorage.getItem('IsLanguage'))
        return isLang === true || isLang === 'true'
      } catch (e) {
        return localStorage.getItem('IsLanguage') === 'true'
      }
    }
  },
  mounted() {
    this.syncLocale()
    this.updateWindowTitle()
    window.addEventListener('storage', this.onStorageChange)
    const urlParams = new URLSearchParams(window.location.search)
    vueData.AssignToClassID = parseInt(urlParams.get('AssignToClassID')) || 0
    vueData.AssignToStudentID = parseInt(urlParams.get('AssignToStudentID')) || 0
    vueData.AssignmentID = parseInt(urlParams.get('AssignmentID')) || 0
    vueData.HocKi = localStorage.getItem('HocKi') ?? 1
    this.initPage()
  },
  beforeUnmount() {
    window.removeEventListener('storage', this.onStorageChange)
  },
  methods: {
    syncLocale() {
      try {
        const isLang = JSON.parse(localStorage.getItem('IsLanguage')) ?? false
        if (this.$i18n) {
          this.$i18n.locale = (isLang === true || isLang === 'true') ? 'en' : 'vi'
        }
      } catch (e) {
        if (this.$i18n) {
          this.$i18n.locale = localStorage.getItem('IsLanguage') === 'true' ? 'en' : 'vi'
        }
      }
    },
    onStorageChange(e) {
      if (e.key === 'IsLanguage') {
        this.syncLocale()
        this.updateWindowTitle()
      }
    },
    updateWindowTitle(customTitle) {
      const defaultTitle = this.IsEngLish ? 'Edit assignment' : 'Sửa bài tập'
      const title = customTitle || (this.assignment?.Title ? this.assignment.Title : defaultTitle)
      if (window !== window.top) {
        window.parent.postMessage({ type: 'iframeRef_setTitle', title }, '*')
      }
    },
    formatErrorMessage(msg) {
      if (!msg) return this.IsEngLish ? 'Unable to load assignment' : 'Không thể tải bài tập'
      if (this.IsEngLish) {
        const str = String(msg).trim()
        if (str.includes('học sinh đang làm bài') || str.includes('không thể sửa bài')) {
          return 'A student is already taking this assignment. You cannot edit it.'
        }
        if (str.includes('không có quyền') || str.includes('Bạn không có quyền')) {
          return 'You do not have permission to edit this assignment.'
        }
        if (str.includes('Không tìm thấy') || str.includes('không tìm thấy')) {
          return 'Assignment not found.'
        }
      }
      return msg
    },
    retryInit() {
      this.errorMessage = ''
      this.dataReady = false
      this.initPage()
    },
    async initPage() {
      this.errorMessage = ''
      try {
        const IsLanguage = JSON.parse(localStorage.getItem('IsLanguage')) ?? false
        const assignmentId = vueData.AssignmentID

        const asmDefault = {
          version: '1.2',
          type: 'GROUPED_MIXED',
          groups: [{
            id: 'group_' + Date.now(),
            title: IsLanguage ? 'Section 1' : 'Phần 1',
            media: {
              type: 'YOUTUBE',
              sourceYT: { id: '', source: '', name: '' },
              sourceRecord: { id: '', source: '', name: '' },
              sourceFiles: { file: [], image: [] },
            },
            description: '',
            content: '',
            advancedFeatures: { isShuffleQuestions: false, isShuffleAnswers: false },
            questions: [],
          }],
        }

        if (assignmentId && assignmentId > 0) {
          this.isEditMode = true
          let apiUrl = 'lms/EL_Teacher_GetAssignmentForEdit'
          let apiParams = { AssignmentID: assignmentId }
          if (vueData.AssignToClassID) {
            apiParams.AssignToClassID = vueData.AssignToClassID
          } else if (vueData.AssignToStudentID) {
            apiUrl = 'lms/EL_Teacher_GetAssignmentForEdit_Student'
            apiParams.AssignToStudentID = vueData.AssignToStudentID
          }
          // Bật cache: true để khi switch/untab browser quay lại không bị gọi API fetch đè lại dữ liệu đang chỉnh sửa.
          const res = await fetchPromise(apiUrl, apiParams, { cache: true, useStaleCacheOnError: false })
          let assignmentData = { ...(res?.[0] ?? {}) }

          if (assignmentData.hasOwnProperty('Is_Full_Quiz')) {
            assignmentData.Is_Full_Quiz = !!assignmentData.Is_Full_Quiz
          }

          if (!assignmentData.AssignmentConfig) {
            assignmentData.AssignmentConfig = asmDefault
          } else {
            try {
              if (typeof assignmentData.AssignmentConfig === 'string') {
                assignmentData.AssignmentConfig = JSON.parse(assignmentData.AssignmentConfig) || asmDefault
              }
              if (assignmentData.AssignmentConfig?.type === 'INTEGRATED') {
                assignmentData.AssignmentType = 'INTEGRATED'
                assignmentData.IntegrationSource = assignmentData.IntegrationSource || assignmentData.AssignmentConfig.source || ''
                assignmentData.ExternalLink = assignmentData.AssignmentConfig.link || assignmentData.Instructions || ''
                if (!assignmentData.AssignmentConfig.groups) {
                  assignmentData.AssignmentConfig.groups = []
                }
              } else {
                assignmentData.AssignmentType = 'LMS'
                assignmentData.IntegrationSource = ''
                assignmentData.ExternalLink = ''
              }
            } catch (e) {
              assignmentData.AssignmentConfig = asmDefault
            }
          }
          vueData.assignment = assignmentData
          this.assignment = assignmentData
        } else {
          this.isEditMode = false
          const newAssignment = {
            Title: '',
            Instructions: '',
            MonHocLopID: null,
            AssignmentType: 'LMS',
            IntegrationSource: '',
            AssignmentConfig: {
              version: '1.2',
              type: 'GROUPED_MIXED',
              groups: [{
                id: 'group_' + crypto.randomUUID(),
                title: IsLanguage ? 'Section 1' : 'Phần 1',
                description: '',
                content: '',
                AdvancedFeatures: { isShuffleQuestions: false, isShuffleAnswers: false },
                questions: [],
                media: {
                  type: 'YOUTUBE',
                  sourceYT: { id: '', source: '', name: '' },
                  sourceRecord: { id: '', source: '', name: '' },
                  sourceFiles: { file: [], image: [] },
                },
              }],
            },
            MaxScore: 10,
            Status: 1,
          }
          vueData.assignment = newAssignment
          this.assignment = newAssignment
        }
        this.updateWindowTitle(this.assignment?.Title)
        this.dataReady = true
      } catch (error) {
        console.error('Lỗi khởi tạo builder bài tập:', error)
        this.errorMessage = error?.message || (this.IsEngLish ? 'Unable to load assignment' : 'Không thể tải bài tập')
        this.updateWindowTitle(this.IsEngLish ? 'Edit assignment' : 'Sửa bài tập')
        this.dataReady = false
      }
    },

    // MaxScore của LMS phải phản ánh số câu thực tế mỗi lượt làm bài.
    // Group mặc định cộng toàn bộ câu; group RANDOM quy đổi theo số câu được lấy.
    getEffectiveGroupScore(group) {
      const questions = Array.isArray(group?.questions) ? group.questions : []
      const poolScore = questions.reduce((sum, question) => {
        const points = Number(question?.points ?? 0)
        return sum + (Number.isFinite(points) && points > 0 ? points : 0)
      }, 0)
      if (group?.questionSelection?.mode !== 'RANDOM') return poolScore

      const requested = Math.floor(Number(group.questionSelection?.questionsPerAttempt))
      const count = Math.min(
        Math.max(Number.isFinite(requested) ? requested : 0, 0),
        questions.length
      )
      return questions.length ? poolScore * (count / questions.length) : 0
    },

    _buildPayload(payload) {
      const dataToSend = {
        ...payload.assignment,
        Type: payload.assignment.AssignmentType,
        AssignmentID: vueData.AssignmentID || 0,
        AssignToClassID: vueData.AssignToClassID || 0,
        Is_Full_Quiz: payload.Is_Full_Quiz ? 1 : 0,
        IsBlockCopy_Paste: payload.setting?.IsBlockCopy_Paste,
      }
      dataToSend.Status = payload.isPublishing ? 2 : 1

      const groups = payload.assignment.AssignmentConfig?.groups || []
      let MaxScore = 0
      
      const isIntegration = payload.assignment.AssignmentType === 'INTEGRATED' || (payload.assignment.IntegrationSource && payload.assignment.IntegrationSource !== 'LMS')

      if (isIntegration || payload.assignment.ExternalLink) {
        MaxScore = Number(payload.assignment.MaxScore) || 10
      } else {
        dataToSend.IntegrationSource = 'LMS'
        for (const group of groups) {
          MaxScore += this.getEffectiveGroupScore(group)
        }
      }
      dataToSend.MaxScore = MaxScore

      if (payload.assignment.ExternalLink) {
        dataToSend.AssignmentConfig = JSON.stringify({ version: '1.2', type: 'INTEGRATED', source: payload.assignment.IntegrationSource, link: payload.assignment.ExternalLink })
        dataToSend.AssignmentConfig_NoAnswer = dataToSend.AssignmentConfig
      } else {
        const fullConfig = payload.assignment.AssignmentConfig || { groups: [] }
        fullConfig.type = 'GROUPED_MIXED'
        if (!fullConfig.groups) fullConfig.groups = []

        const cloneGroup = _.cloneDeep(fullConfig)

        for (const group of cloneGroup.groups) {
          group.questions = group.questions.map(x => {
            if (x.type === 'QUIZ_SINGLE_CHOICE') x.config.correctAnswer = null
            if (x.type === 'QUIZ_MULTIPLE_CHOICE') x.config.correctAnswers = []
            if (x.type === 'QUIZ_TRUE_FALSE') x.config.correctAnswer = null
            if (x.type === 'QUIZ_MULTIPLE_TRUE_FALSE') x.config.options = x.config.options.map(n => ({ ...n, inCorrectAnswer: null, correctAnswer: null }))
            if (x.type === 'QUIZ_FILL_IN_BLANK') x.config.parts = x.config.parts.map(n => { if (n.type === 'blank') n.acceptedAnswers = []; return n })
            if (x.type === 'QUIZ_MATCHING') x.config.correctPairs = []
            return x
          })
        }
        dataToSend.AssignmentConfig_NoAnswer = JSON.stringify(cloneGroup)
        dataToSend.AssignmentConfig = JSON.stringify(fullConfig)
      }
      delete dataToSend.HocLieuID
      delete dataToSend.NoiDungID
      delete dataToSend.TenHocLieu
      delete dataToSend.TenNoiDung
      return dataToSend
    },

    async saveAssignment(payload) {
      const dataToSend = this._buildPayload(payload)
      const res = await fetchPromise('lms/EL_Teacher_SaveAssignment', dataToSend, { cache: false })
      if (!res) return null

      this.snackbarRef.value.showSnackbar({ message: 'Lưu bài tập thành công', color: 'success' })
      const urlParams = new URLSearchParams(window.location.search)
      
      if (!this.isEditMode && res?.[0]?.AssignmentID) {
        const newId = res[0].AssignmentID
        window.history.pushState({}, '', `?AssignmentID=${newId}`)
        vueData.AssignmentID = newId
        this.isEditMode = true
        payload.assignment.AssignmentID = newId
        const savedAssignment = JSON.parse(JSON.stringify(payload.assignment))
        savedAssignment.AssignmentID = newId
        this.assignment = savedAssignment
        vueData.assignment = savedAssignment
      }

      // Media có thể được upload trước khi bài có AssignmentID hoặc lần đăng ký tài nguyên trước đó bị lỗi.
      // Sau khi lưu thành công, đăng ký lại các media đang chờ để chúng xuất hiện ở Content Hub/Tài liệu.
      try {
        const registeredCount = await this.registerPendingAssignmentMedia(payload.assignment)
        // Lưu lại resourceNodeId/resourceRegistrationPending=false vào AssignmentConfig,
        // tránh đăng ký trùng hoặc để lại node tài nguyên mồ côi sau khi reload bài.
        if (registeredCount > 0) {
          await fetchPromise('lms/EL_Teacher_SaveAssignment', this._buildPayload(payload), { cache: false, silent: true })
        }
      } catch (error) {
        console.error('Lỗi bổ sung media bài tập vào tài nguyên sau khi lưu:', error)
        this.snackbarRef.value.showSnackbar({
          message: 'Bài tập đã lưu nhưng một số media chưa được đưa vào Tài nguyên.',
          color: 'warning',
        })
      }
      return res
    },

    assignmentMediaSources(assignment) {
      const sources = []
      const addMedia = (media, context) => {
        if (!media) return
        if (media.sourceYT?.resourceRegistrationPending) sources.push({ source: media.sourceYT, resourceType: 'VIDEO', context })
        if (media.sourceRecord?.resourceRegistrationPending) sources.push({ source: media.sourceRecord, resourceType: 'AUDIO', context })
          ;['file', 'image'].forEach(type => {
          ;(media.sourceFiles?.[type] || []).forEach(source => {
            // Có resourceNodeId nghĩa là file đã được đăng ký vào một thư viện
            // cụ thể (với bài cũ có thể chưa có resourceLibraryId trong JSON).
            // Không migration lại theo tài khoản đang đăng nhập vì sẽ tạo bản sao
            // sang thư viện khác với chủ bài tập.
            if (source?.resourceRegistrationPending && !source?.resourceNodeId) sources.push({ source, resourceType: type === 'image' ? 'IMAGE' : 'FILE', context })
          })
        })
      }

      ;(assignment?.AssignmentConfig?.groups || []).forEach((group, groupIndex) => {
        addMedia(group?.media, { type: 'group', groupIndex })
        ;(group?.questions || []).forEach((question, qIndex) => {
          addMedia(question?.config?.media, { type: 'question', groupIndex, qIndex })
        })
      })
      return sources
    },

    needsResourceLibraryMigration(source) {
      // Giữ tương thích cho nơi khác còn gọi helper này. Node đã tồn tại thì
      // không được đăng ký lại, dù JSON cũ chưa lưu resourceLibraryId.
      return false
    },

    async resolveAssignmentResourceLibrary(khoiID, monHocID) {
      const libraries = await fetchPromise('lms/FP_TaiNguyen_GetAll', {
        KhoiID: khoiID,
        MonHocID: monHocID,
        TaiNguyenLoaiID: 0,
        TaiNguyenMucID: 0,
      }, { forceRefresh: true, useStaleCacheOnError: false })
      let library = (libraries || []).find(item => item.TaiNguyenLoaiCode === 'TAI_LIEU_THAM_KHAO')
      if (!library) {
        const typeInfo = await fetchPromise('lms/FP_TaiNguyenLoai_GetAll', {}, { cache: false })
        const type = (typeInfo || []).find(item => (item.TaiNguyenLoaiCode || item.Code) === 'TAI_LIEU_THAM_KHAO')
        const result = await fetchPromise('lms/FP_TaiNguyen_Save', {
          HocLieuID: 0,
          TenHocLieu: 'Tài nguyên đã tải lên',
          TaiNguyenLoaiID: type?.TaiNguyenLoaiID,
          KhoiID: khoiID,
          MonHocID: monHocID,
          TinhTrang: 'Private',
        }, { cache: false })
        library = Array.isArray(result) ? result[0] : result
      }
      if (!library?.HocLieuID) throw new Error('Không xác định được bộ tài nguyên của Khối/Môn hiện tại')
      return library.HocLieuID
    },

    async registerPendingAssignmentMedia(assignment) {
      const assignmentID = Number(assignment?.AssignmentID || vueData?.AssignmentID || 0)
      if (!assignmentID) return

      const pending = this.assignmentMediaSources(assignment)
      // Phần lớn lần save chỉ cập nhật nội dung bài. Không có media mới thì
      // không cần gọi lookup thư viện tài nguyên và không tạo thêm một nhánh
      // API trong cùng luồng save/preview.
      if (!pending.length) return 0

      const khoiID = Number(assignment?.KhoiID || vueData?.KhoiID || 0)
      const monHocID = Number(assignment?.MonHocID || vueData?.MonHocID || 0)
      if (!khoiID || !monHocID) {
        throw new Error('Bài tập chưa có đủ Khối/Môn để đăng ký media vào Tài nguyên')
      }

      let registeredCount = 0
      const hocLieuID = await this.resolveAssignmentResourceLibrary(khoiID, monHocID)
      for (const item of pending) {
        const source = item.source
        const resourceSource = source?.dbFileId
          ? { ...source, id: source.dbFileId, source: source.dbSource, mediaSource: source.dbMediaSource || 'db' }
          : source
        const metadata = {
          uploadSource: resourceSource.mediaSource === 'db'
            ? 'db'
            : (resourceSource.mediaSource === 'upload' && /youtube\.com|youtu\.be/i.test(resourceSource.source || '') ? 'youtube' : 'gdrive'),
          fileId: resourceSource.id,
          fileName: source.name || 'Media bài tập',
          contentType: source.contentType || '',
          fileSize: Number(resourceSource.fileSize || 0),
          url: resourceSource.source,
          ...(source?.dbFileId ? {
            dbFileId: source.dbFileId,
            resourceFileId: source.resourceFileId || source.dbFileId,
            dbSource: source.dbSource || `/FileData/${source.dbFileId}`,
            storage: 'LMS_LHBS_FILEDATA',
          } : {}),
          ...(source?.externalId || source?.externalSource ? {
            externalId: source.externalId || '',
            externalUrl: source.externalSource || '',
          } : {}),
          origin: 'GIAO_BAI',
          publishSource: item.resourceType,
          assignmentID,
          mediaContext: item.context,
        }
        if (!metadata.fileId) throw new Error(`Media “${metadata.fileName}” không có mã file`)

        const response = await fetchPromise('lms/FP_TaiNguyen_Node_Save', {
          NoiDungID: 0,
          HocLieuID: hocLieuID,
          ParentID: null,
          TenNoiDung: metadata.fileName,
          LoaiNoiDung: item.resourceType,
          NguonTaiNguyenCode: 'GIAO_BAI',
          NguonResourceType: 'ASSIGNMENT',
          NguonResourceID: assignmentID,
          ThuTu: 0,
          User: vueData?.user?.UserID || '',
          DataJson: JSON.stringify(metadata),
        }, { cache: false })
        const registered = Array.isArray(response) ? response[0] : response
        if (!registered?.NoiDungID) throw new Error(`Không đăng ký được media “${metadata.fileName}” vào Tài nguyên`)
        source.resourceNodeId = registered.NoiDungID
        source.resourceLibraryId = hocLieuID
        source.resourceFileId = source.resourceFileId || source.dbFileId || (source.mediaSource === 'db' ? source.id : '')
        source.resourceRegistrationPending = false
        registeredCount += 1
      }
      return registeredCount
    },

    async autoSaveAssignment(payload) {
      const dataToSend = this._buildPayload({ ...payload, isPublishing: false })
      const res = await fetchPromise('lms/EL_Teacher_SaveAssignment', dataToSend, { cache: false, silent: true })
    },
  },
	}
</script>