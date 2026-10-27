<template>
	<div class="wf-watchers">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between mb-3">
      <div class="d-flex align-center text-caption font-weight-bold text-grey-darken-1"
        style="font-size: 11px !important; text-transform: uppercase;">
        <v-icon size="14" class="mr-1">mdi-eye-outline</v-icon>
        Theo dõi
      </div>
      <v-btn :color="isWatching ? 'primary' : 'grey'" :variant="isWatching ? 'tonal' : 'outlined'" height="24"
        class="font-weight-bold px-2" style="font-size: 10px; text-transform: none; border-radius: 4px;"
        :loading="isToggling" @click="toggleWatch">
        <v-icon start size="12">{{ isWatching ? 'mdi-eye' : 'mdi-eye-plus-outline' }}</v-icon>
        {{ isWatching ? 'Đang theo dõi' : 'Theo dõi' }}
      </v-btn>
    </div>

    <!-- Watcher list -->
    <div v-if="watchers.length > 0" class="d-flex flex-wrap ga-1">
      <v-tooltip v-for="w in watchers" :key="w.UserID" location="top" :text="w.UserFullName || w.UserID">
        <template v-slot:activator="{ props }">
          <div v-bind="props"
            style="width: 24px; height: 24px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 9px; font-weight: 700; background: #64748b; color: #fff; cursor: default;">
            {{ getInitial(w.UserFullName || w.UserID) }}
          </div>
        </template>
      </v-tooltip>
    </div>
    <div v-else class="text-caption text-grey italic" style="font-size: 10px;">Chưa có ai theo dõi.</div>
  </div>
</template>

<script>
	export default {
		name: 'uc-instance-watchers',
  props: {
    instanceId: { type: Number, default: 0 }
  },
  data: function () {
    return {
      watchers: [],
      isToggling: false
    }
  },
  computed: {
    currentUserId: function () {
      var user = (typeof vueData !== 'undefined' && vueData.user) ? vueData.user : {}
      return String(user.UserID || '')
    },
    isWatching: function () {
      var uid = this.currentUserId
      return this.watchers.some(function (w) { return String(w.UserID) === uid })
    }
  },
  watch: {
    instanceId: function (val) {
      if (val) this.loadWatchers()
    }
  },
  mounted: function () {
    if (this.instanceId) this.loadWatchers()
  },
  methods: {
    loadWatchers: async function () {
      if (!this.instanceId) return
      try {
        var res = await apiCallAsync('WF_InstanceWatcher_GetList', { InstanceID: this.instanceId })
        this.watchers = Array.isArray(res) ? res : []
      } catch (e) {
        this.watchers = []
      }
    },

    toggleWatch: async function () {
      if (this.isToggling) return
      this.isToggling = true
      try {
        if (this.isWatching) {
          await apiCallAsync('WF_InstanceWatcher_Delete', { InstanceID: this.instanceId })
          showToast.info('Đã bỏ theo dõi.')
        } else {
          await apiCallAsync('WF_InstanceWatcher_Save', { InstanceID: this.instanceId })
          showToast.success('Đang theo dõi hồ sơ này.')
        }
        await this.loadWatchers()
      } catch (e) {
        // error handled by apiCallAsync
      } finally {
        this.isToggling = false
      }
    },

    getInitial: function (name) {
      return String(name || 'U').charAt(0).toUpperCase()
    }
  }
	}
</script>