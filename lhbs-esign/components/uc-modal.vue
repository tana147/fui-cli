<template>
	<v-dialog :model-value="modelValue" :max-width="maxWidth" :persistent="persistent" :fullscreen="fullscreen"
    @update:model-value="$emit('update:modelValue', $event)">
    <v-card class="uc-modal-card">
      <!-- Header -->
      <div class="uc-modal-header">
        <div class="uc-modal-header-content">
          <div class="uc-modal-title">{{ title }}</div>
          <div v-if="subtitle" class="uc-modal-subtitle">{{ subtitle }}</div>
        </div>
        <v-btn v-if="showClose" icon="mdi-close" variant="text" size="small" color="white" class="uc-modal-close"
          @click="$emit('update:modelValue', false)">
        </v-btn>
      </div>

      <!-- Body -->
      <div class="uc-modal-body" :style="bodyStyle">
        <slot></slot>
      </div>

      <!-- Footer -->
      <div v-if="$slots.actions || confirmText" class="uc-modal-footer">
        <slot name="actions">
          <v-btn v-if="cancelText" variant="outlined" color="grey-darken-2" height="34" class="uc-modal-btn-cancel"
            @click="$emit('update:modelValue', false)">
            <v-icon v-if="cancelIcon" start size="15">{{ cancelIcon }}</v-icon>
            {{ cancelText }}
          </v-btn>
          <v-btn v-if="confirmText" color="primary" variant="flat" height="34" class="uc-modal-btn-confirm"
            :loading="loading" @click="$emit('confirm')">
            <v-icon v-if="confirmIcon" start size="15">{{ confirmIcon }}</v-icon>
            {{ confirmText }}
          </v-btn>
        </slot>
      </div>
    </v-card>
  </v-dialog>
</template>

<script>
	export default {
		props: {
      modelValue:  { type: Boolean, default: false },
      title:       { type: String, default: '' },
      subtitle:    { type: String, default: '' },
      maxWidth:    { type: [String, Number], default: 560 },
      persistent:  { type: Boolean, default: false },
      fullscreen:  { type: Boolean, default: false },
      showClose:   { type: Boolean, default: true },
      loading:     { type: Boolean, default: false },
      confirmText: { type: String, default: '' },
      confirmIcon: { type: String, default: 'mdi-content-save-outline' },
      cancelText:  { type: String, default: '' },
      cancelIcon:  { type: String, default: 'mdi-close' },
      maxBodyHeight: { type: String, default: '65vh' },
      bodyPadding:   { type: String, default: '20px 24px' }
    },
    emits: ['update:modelValue', 'confirm'],
    computed: {
      bodyStyle: function () {
        return { 'max-height': this.fullscreen ? 'none' : this.maxBodyHeight, 'overflow-y': 'auto', 'padding': this.bodyPadding }
      }
    }
	}
</script>