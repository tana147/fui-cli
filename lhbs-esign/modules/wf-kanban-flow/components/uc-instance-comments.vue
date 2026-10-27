<template>
	<div class="wf-comments">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between mb-4 pb-3" style="border-bottom: 1px solid #e2e8f0;">
      <div class="d-flex align-center ga-2">
        <v-icon size="18" color="primary">mdi-comment-multiple-outline</v-icon>
        <span class="text-subtitle-2 font-weight-bold text-grey-darken-4 text-uppercase"
          style="font-size: 13px !important;">Bình luận</span>
      </div>
      <v-chip size="x-small" color="primary" variant="tonal" class="font-weight-bold px-2">
        {{ comments.length }}
      </v-chip>
    </div>

    <!-- Comment input -->
    <div class="mb-4">
      <div class="d-flex align-start ga-2">
        <div class="wf-comment-avatar flex-shrink-0"
          style="width: 32px; height: 32px; border-radius: 50%; background: #217D46; color: #fff; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 700;">
          {{ currentUserInitial }}
        </div>
        <div class="flex-grow-1">
          <v-textarea v-model="newComment" placeholder="Thêm bình luận..." variant="outlined" density="compact" rows="2"
            hide-details auto-grow max-rows="6" class="wf-ant-input bg-white" style="font-size: 13px;"
            @keydown.ctrl.enter="submitComment" @keydown.meta.enter="submitComment" />
          <div class="d-flex align-center justify-space-between mt-2">
            <span class="text-caption text-grey" style="font-size: 10px;">Ctrl+Enter để gửi</span>
            <v-btn color="primary" variant="flat" height="28" class="font-weight-bold text-caption text-white px-4"
              :loading="isSending" :disabled="!newComment.trim()" @click="submitComment"
              style="text-transform: none; border-radius: 4px; font-size: 12px !important;">
              <v-icon start size="14">mdi-send</v-icon>
              Gửi
            </v-btn>
          </div>
        </div>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="isLoading" class="text-center py-4">
      <v-progress-circular indeterminate color="primary" size="24" />
    </div>

    <!-- Comments list -->
    <div v-else-if="comments.length > 0" class="d-flex flex-column ga-3">
      <div v-for="comment in comments" :key="comment.CommentID" class="d-flex align-start ga-2">
        <!-- Avatar -->
        <div class="flex-shrink-0"
          style="width: 32px; height: 32px; border-radius: 50%; background: #64748b; color: #fff; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 700;">
          {{ getInitial(comment.UserID) }}
        </div>
        <!-- Bubble -->
        <div class="flex-grow-1">
          <div class="rounded-lg pa-3 bg-grey-lighten-5 border"
            style="border-color: #e2e8f0 !important; position: relative;">
            <!-- Header -->
            <div class="d-flex align-center justify-space-between mb-1">
              <div class="d-flex align-center ga-2">
                <span class="text-caption font-weight-bold text-grey-darken-4" style="font-size: 12px !important;">
                  {{ comment.UserFullName || comment.UserID }}
                </span>
                <v-chip v-if="isCurrentUser(comment.UserID)" size="x-small" color="primary" variant="tonal" class="px-1"
                  style="height: 16px; font-size: 9px;">Tôi</v-chip>
              </div>
              <div class="d-flex align-center ga-1">
                <span class="text-caption text-grey" style="font-size: 10px;">
                  {{ formatDateTime(comment.CreateTime) }}
                  <span v-if="comment.IsEdited" class="text-grey-lighten-1">(đã chỉnh sửa)</span>
                </span>
                <!-- Actions for own comments -->
                <v-menu v-if="isCurrentUser(comment.UserID)" transition="slide-y-transition" offset="4">
                  <template v-slot:activator="{ props }">
                    <v-btn v-bind="props" icon size="x-small" variant="text" color="grey"
                      style="width: 20px; height: 20px;">
                      <v-icon size="14">mdi-dots-horizontal</v-icon>
                    </v-btn>
                  </template>
                  <v-list density="compact" class="py-1" style="min-width: 120px;">
                    <v-list-item @click="startEdit(comment)" style="min-height: 32px;">
                      <template v-slot:prepend>
                        <v-icon size="14" class="mr-2">mdi-pencil-outline</v-icon>
                      </template>
                      <v-list-item-title style="font-size: 12px;">Chỉnh sửa</v-list-item-title>
                    </v-list-item>
                    <v-list-item @click="deleteComment(comment)" style="min-height: 32px;" class="text-error">
                      <template v-slot:prepend>
                        <v-icon size="14" color="error" class="mr-2">mdi-delete-outline</v-icon>
                      </template>
                      <v-list-item-title style="font-size: 12px; color: inherit;">Xóa</v-list-item-title>
                    </v-list-item>
                  </v-list>
                </v-menu>
              </div>
            </div>

            <!-- Content (view mode) -->
            <div v-if="editingCommentId !== comment.CommentID"
              class="text-caption text-grey-darken-3 white-space-pre-wrap"
              style="font-size: 13px !important; line-height: 1.5; word-break: break-word;">
              {{ comment.Content }}
            </div>

            <!-- Content (edit mode) -->
            <div v-else>
              <v-textarea v-model="editContent" variant="outlined" density="compact" rows="2" hide-details auto-grow
                max-rows="6" class="wf-ant-input bg-white mb-2" style="font-size: 13px;" autofocus />
              <div class="d-flex ga-2 justify-end">
                <v-btn size="small" variant="text" height="26" class="font-weight-bold text-caption" @click="cancelEdit"
                  style="text-transform: none; font-size: 11px;">
                  Hủy
                </v-btn>
                <v-btn color="primary" size="small" variant="flat" height="26"
                  class="font-weight-bold text-caption text-white px-3" :loading="isSaving"
                  :disabled="!editContent.trim()" @click="saveEdit(comment)"
                  style="text-transform: none; font-size: 11px;">
                  Lưu
                </v-btn>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty state -->
    <div v-else class="text-center py-6 text-caption text-grey">
      <v-icon size="32" color="grey-lighten-1" class="mb-1">mdi-comment-off-outline</v-icon>
      <div>Chưa có bình luận nào.</div>
    </div>
  </div>
</template>

<script>
	export default {
		name: 'uc-instance-comments',
  props: {
    instanceId: { type: Number, default: 0 }
  },
  data: function () {
    return {
      comments: [],
      newComment: '',
      isLoading: false,
      isSending: false,
      isSaving: false,
      editingCommentId: null,
      editContent: ''
    }
  },
  computed: {
    currentUserInitial: function () {
      var user = (typeof vueData !== 'undefined' && vueData.user) ? vueData.user : {}
      var name = user.FirstName || user.UserID || 'U'
      return String(name).charAt(0).toUpperCase()
    },
    currentUserId: function () {
      var user = (typeof vueData !== 'undefined' && vueData.user) ? vueData.user : {}
      return user.UserID || ''
    }
  },
  watch: {
    instanceId: function (val) {
      if (val) this.loadComments()
    }
  },
  mounted: function () {
    if (this.instanceId) this.loadComments()
  },
  methods: {
    loadComments: async function () {
      if (!this.instanceId) return
      this.isLoading = true
      try {
        var res = await apiCallAsync('WF_InstanceComment_GetList', { InstanceID: this.instanceId })
        this.comments = Array.isArray(res) ? res : []
      } catch (e) {
        this.comments = []
      } finally {
        this.isLoading = false
      }
    },

    submitComment: async function () {
      var text = this.newComment.trim()
      if (!text || this.isSending) return
      this.isSending = true
      try {
        await apiCallAsync('WF_InstanceComment_Save', {
          InstanceID: this.instanceId,
          Content: text
        })
        this.newComment = ''
        await this.loadComments()
        showToast.success('Đã thêm bình luận.')
      } catch (e) {
        // apiCallAsync shows error toast automatically
      } finally {
        this.isSending = false
      }
    },

    startEdit: function (comment) {
      this.editingCommentId = comment.CommentID
      this.editContent = comment.Content
    },

    cancelEdit: function () {
      this.editingCommentId = null
      this.editContent = ''
    },

    saveEdit: async function (comment) {
      var text = this.editContent.trim()
      if (!text || this.isSaving) return
      this.isSaving = true
      try {
        await apiCallAsync('WF_InstanceComment_Save', {
          CommentID: comment.CommentID,
          InstanceID: this.instanceId,
          Content: text
        })
        this.cancelEdit()
        await this.loadComments()
        showToast.success('Đã cập nhật bình luận.')
      } catch (e) {
        // handled
      } finally {
        this.isSaving = false
      }
    },

    deleteComment: function (comment) {
      var self = this
      showConfirm('Xóa bình luận này?', async function () {
        try {
          await apiCallAsync('WF_InstanceComment_Delete', { CommentID: comment.CommentID })
          await self.loadComments()
          showToast.success('Đã xóa bình luận.')
        } catch (e) {
          // handled
        }
      })
    },

    isCurrentUser: function (userId) {
      return userId && String(userId) === String(this.currentUserId)
    },

    getInitial: function (userId) {
      return String(userId || 'U').charAt(0).toUpperCase()
    },

    formatDateTime: function (val) {
      if (!val) return '—'
      var dt = new Date(val)
      if (isNaN(dt.getTime())) return val
      var hh = String(dt.getHours()).padStart(2, '0')
      var mm = String(dt.getMinutes()).padStart(2, '0')
      var dd = String(dt.getDate()).padStart(2, '0')
      var mo = String(dt.getMonth() + 1).padStart(2, '0')
      var yyyy = dt.getFullYear()
      return hh + ':' + mm + ' ' + dd + '/' + mo + '/' + yyyy
    }
  }
	}
</script>