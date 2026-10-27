<template>
	<div class="wf-notification-wrapper" style="position: relative;">
    <!-- Bell trigger -->
    <v-btn icon size="small" variant="text" color="white" style="opacity: 0.8;"
      @click="toggle">
      <v-badge :content="unreadCount" :model-value="unreadCount > 0" color="error" size="x-small">
        <v-icon size="18">mdi-bell-outline</v-icon>
      </v-badge>
    </v-btn>

    <!-- Dropdown -->
    <div v-if="isOpen" class="wf-notification-panel"
      v-click-outside="close">
      <!-- Header -->
      <div class="d-flex align-center justify-space-between px-4 py-3 border-bottom"
        style="border-bottom: 1px solid #f1f5f9 !important;">
        <span class="text-subtitle-2 font-weight-bold text-grey-darken-4">Thông báo</span>
        <div class="d-flex ga-1">
          <v-btn v-if="unreadCount > 0" variant="text" color="primary" height="24"
            class="text-caption font-weight-medium px-2" style="font-size: 10px !important; text-transform: none;"
            :loading="isMarkingAll" @click="markAllRead">
            Đọc tất cả
          </v-btn>
          <v-btn icon size="x-small" variant="text" color="grey" @click="loadNotifications">
            <v-icon size="14">mdi-refresh</v-icon>
          </v-btn>
        </div>
      </div>

      <!-- Loading -->
      <div v-if="isLoading" class="d-flex justify-center py-6">
        <v-progress-circular indeterminate color="primary" size="20" />
      </div>

      <!-- Empty -->
      <div v-else-if="notifications.length === 0" class="text-center py-6 px-4">
        <v-icon size="32" color="grey-lighten-1">mdi-bell-off-outline</v-icon>
        <div class="text-caption text-grey mt-2">Không có thông báo nào.</div>
      </div>

      <!-- Notification list -->
      <div v-else class="wf-notification-list">
        <div v-for="n in notifications" :key="n.NotificationID"
          class="wf-notification-item d-flex ga-3 px-4 py-3 cursor-pointer border-bottom"
          style="border-bottom: 1px solid #f8fafc !important; transition: background 0.1s;"
          :style="!n.IsRead ? 'background: #eff6ff;' : ''"
          @click="handleClick(n)">

          <!-- Icon -->
          <div style="width: 32px; height: 32px; border-radius: 50%; flex-shrink: 0; display: flex; align-items: center; justify-content: center;"
            :style="{ background: getIconBg(n.NotificationType) }">
            <v-icon size="15" :color="getIconColor(n.NotificationType)">
              {{ getIcon(n.NotificationType) }}
            </v-icon>
          </div>

          <!-- Content -->
          <div class="flex-grow-1 min-w-0">
            <div class="text-caption text-grey-darken-4 mb-0.5"
              style="font-size: 12px !important; line-height: 1.4;">{{ n.Message }}</div>
            <div class="text-caption text-grey" style="font-size: 10px !important;">
              {{ formatTime(n.CreateTime) }}
            </div>
          </div>

          <!-- Unread dot -->
          <div v-if="!n.IsRead" style="width: 7px; height: 7px; border-radius: 50%; background: #3b82f6; flex-shrink: 0; margin-top: 4px;"></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		name: 'uc-notification-dropdown',
  data() {
    return {
      isOpen: false,
      isLoading: false,
      isMarkingAll: false,
      notifications: [],
      unreadCount: 0,
      pollTimer: null
    }
  },
  mounted() {
    this.loadUnreadCount()
    this.startPolling()
  },
  beforeUnmount() {
    clearInterval(this.pollTimer)
  },
  methods: {
    toggle: function () {
      this.isOpen = !this.isOpen
      if (this.isOpen) this.loadNotifications()
    },
    close: function () {
      this.isOpen = false
    },
    startPolling: function () {
      var self = this
      this.pollTimer = setInterval(function () { self.loadUnreadCount() }, 30000)
    },
    loadUnreadCount: async function () {
      try {
        var res = await apiCallAsync('WF_Notification_GetUnreadCount', {})
        this.unreadCount = Number((res && res.UnreadCount) || 0)
      } catch (e) {
        // silent
      }
    },
    loadNotifications: async function () {
      this.isLoading = true
      try {
        var res = await apiCallAsync('WF_Notification_GetList', { PageSize: 20 })
        this.notifications = res || []
        this.unreadCount = this.notifications.filter(function (n) { return !n.IsRead }).length
      } catch (e) {
        // silent
      } finally {
        this.isLoading = false
      }
    },
    markAllRead: async function () {
      this.isMarkingAll = true
      try {
        await apiCallAsync('WF_Notification_MarkRead', { MarkAll: true })
        this.notifications.forEach(function (n) { n.IsRead = true })
        this.unreadCount = 0
      } catch (e) {
        // handled
      } finally {
        this.isMarkingAll = false
      }
    },
    handleClick: async function (n) {
      if (!n.IsRead) {
        try {
          await apiCallAsync('WF_Notification_MarkRead', { NotificationID: n.NotificationID })
          n.IsRead = true
          if (this.unreadCount > 0) this.unreadCount--
        } catch (e) {
          // silent
        }
      }
      if (n.InstanceID) {
        window.location.href = '/wf-kanban-flow-detail?id=' + n.InstanceID
      }
      this.isOpen = false
    },
    getIcon: function (type) {
      return { ASSIGNED: 'mdi-account-arrow-right', MENTION: 'mdi-at', WATCH: 'mdi-eye', STEP_CHANGE: 'mdi-arrow-right', COMMENT: 'mdi-comment', COMPLETED: 'mdi-check-circle' }[type] || 'mdi-bell'
    },
    getIconBg: function (type) {
      return { ASSIGNED: '#eff6ff', MENTION: '#fdf4ff', WATCH: '#f0fdf4', STEP_CHANGE: '#fff7ed', COMMENT: '#eff6ff', COMPLETED: '#f0fdf4' }[type] || '#f8fafc'
    },
    getIconColor: function (type) {
      return { ASSIGNED: '#3b82f6', MENTION: '#a855f7', WATCH: '#22c55e', STEP_CHANGE: '#f97316', COMMENT: '#3b82f6', COMPLETED: '#22c55e' }[type] || '#94a3b8'
    },
    formatTime: function (val) {
      if (!val) return ''
      var d = new Date(val)
      var now = new Date()
      var diff = Math.floor((now - d) / 1000)
      if (diff < 60) return 'Vừa xong'
      if (diff < 3600) return Math.floor(diff / 60) + ' phút trước'
      if (diff < 86400) return Math.floor(diff / 3600) + ' giờ trước'
      return String(d.getDate()).padStart(2, '0') + '/' + String(d.getMonth() + 1).padStart(2, '0') + '/' + d.getFullYear()
    }
  },
  directives: {
    'click-outside': {
      mounted(el, binding) {
        el._clickOutside = function (e) {
          if (!el.contains(e.target)) binding.value()
        }
        document.addEventListener('mousedown', el._clickOutside)
      },
      unmounted(el) {
        document.removeEventListener('mousedown', el._clickOutside)
      }
    }
  }
	}
</script>