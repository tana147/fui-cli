<template>
	<div class="wf-free-sign-sidebar">
    <div class="wf-free-sign-sidebar__group">
      <div class="wf-free-sign-sidebar__title">Trang</div>
      <div class="wf-free-sign-page-nav">
        <v-btn variant="text" size="small" icon="mdi-chevron-left" :disabled="activePage <= 1" @click="$emit('prev-page')"></v-btn>
        <div class="wf-free-sign-page-nav__current">{{ activePage }}</div>
        <v-btn variant="text" size="small" icon="mdi-chevron-right" :disabled="activePage >= maxPage" @click="$emit('next-page')"></v-btn>
      </div>
      <div class="wf-free-sign-page-list wf-free-sign-page-list--vertical">
        <div v-for="pageNo in visiblePageOptions" :key="'page-' + pageNo" class="wf-free-sign-page-thumb" :class="{ active: activePage === pageNo }" @click="$emit('set-active-page', pageNo)">
          <div v-if="thumbnailMap[pageNo]" class="wf-free-sign-page-thumb__image-wrap">
            <img :src="thumbnailMap[pageNo]" :alt="'Trang ' + pageNo" class="wf-free-sign-page-thumb__image">
          </div>
          <div v-else="" class="wf-free-sign-page-thumb__placeholder">
            <v-icon size="16" color="grey-lighten-1">mdi-file-pdf-box</v-icon>
          </div>
          <div class="wf-free-sign-page-thumb__label">Trang {{ pageNo }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		name: "uc-free-sign-sidebar",
  props: {
    activePage: { type: Number, default: 1 },
    maxPage: { type: Number, default: 1 },
    visiblePageOptions: { type: Array, default: function () { return [1]; } },
    pageThumbnails: { type: Array, default: function () { return []; } }
  },
  emits: [
    "prev-page",
    "next-page",
    "set-active-page"
  ],
  computed: {
    thumbnailMap: function () {
      var map = {};
      var i = 0;
      for (i = 0; i < this.pageThumbnails.length; i += 1) {
        if (!this.pageThumbnails[i]) continue;
        map[Number(this.pageThumbnails[i].pageNo || 0)] = this.pageThumbnails[i].dataUrl || "";
      }
      return map;
    }
  }
	}
</script>