<template>
	<div class="wf-request-sign-canvas-wrap">
    <div class="wf-request-sign-stage-layout">
      <div class="wf-free-sign-sidebar">
        <div class="wf-free-sign-sidebar__group">
          <div class="wf-free-sign-sidebar__title">Trang</div>
          <div class="wf-free-sign-page-nav">
            <v-btn variant="text" size="small" icon="mdi-chevron-left" :disabled="currentPage <= 1" @click="prevPage"></v-btn>
            <div class="wf-free-sign-page-nav__current">{{ currentPage }}</div>
            <v-btn variant="text" size="small" icon="mdi-chevron-right" :disabled="currentPage >= pageCount" @click="nextPage"></v-btn>
          </div>
          <div class="wf-free-sign-page-list wf-free-sign-page-list--vertical">
            <div v-for="pageNo in pageOptions" :key="pageNo" class="wf-free-sign-page-thumb" :class="{ active: currentPage === pageNo }" @click="setPage(pageNo, true)">
              <div class="wf-free-sign-page-thumb__preview">
                <img v-if="thumbnails[pageNo]" :src="thumbnails[pageNo]" class="wf-free-sign-page-thumb__img" alt="">
                <div v-else class="wf-free-sign-page-thumb__placeholder">
                  <v-icon size="15" color="grey-lighten-1">mdi-file-pdf-box</v-icon>
                </div>
              </div>
              <div class="wf-free-sign-page-thumb__label">{{ pageNo }}</div>
            </div>
          </div>
        </div>
      </div>

      <div class="wf-free-sign-canvas">
        <div ref="viewport" class="wf-free-sign-canvas__viewport" @scroll="onScroll">
          <div v-if="pages.length" class="wf-free-sign-pages">
            <div v-for="page in pages" :key="'pg-' + page.pageNo" class="wf-free-sign-page" :data-page-no="page.pageNo" :style="{ width: page.width + 'px', height: page.height + 'px' }">
              <canvas :id="'wf-request-page-' + page.pageNo" class="wf-free-sign-page__canvas"></canvas>
              <div class="wf-free-sign-page__overlay">
                <div v-for="item in boxesByPage(page.pageNo)" :key="'box-' + item.InstanceSignBoxID" class="wf-free-sign-box wf-request-sign-box" :class="{ active: Number(selectedBoxId || 0) === Number(item.InstanceSignBoxID || 0) }" :data-box-id="item.InstanceSignBoxID" :style="boxStyle(item)" @click.stop="onSelectBox(item)">
                  <span class="wf-free-sign-box__label">{{ boxLabel(item) }}</span>
                </div>
              </div>
            </div>
          </div>
          <div v-else="" class="wf-free-sign-empty">
            <v-icon size="26" color="grey-lighten-1">mdi-file-pdf-box</v-icon>
            <div>Chưa có file PDF để xem.</div>
          </div>
        </div>
        <div class="wf-free-sign-viewer-footer">
          <div class="wf-free-sign-viewer-footer__left">
            <span class="wf-free-sign-viewer-footer__meta">Trang {{ currentPage }}/{{ pageCount }}</span>
            <span class="wf-free-sign-viewer-footer__meta">Box ký: {{ signBoxes.length }}</span>
          </div>
          <div class="wf-free-sign-viewer-zoom">
            <v-btn variant="text" size="small" icon="mdi-minus" @click="zoomOut"></v-btn>
            <span class="wf-free-sign-viewer-zoom__value">{{ zoomPercent }}%</span>
            <v-btn variant="text" size="small" icon="mdi-plus" @click="zoomIn"></v-btn>
            <v-btn class="wf-btn" variant="text" color="primary" size="small" @click="fitToViewport">
              <v-icon start="" size="14">mdi-fit-to-page-outline</v-icon>
              Vừa khung
            </v-btn>
            <div class="wf-free-sign-viewer-zoom__presets">
              <v-btn v-for="preset in zoomPresets" :key="'zoom-' + preset" size="x-small" class="wf-btn" variant="text" color="primary" :class="{ 'wf-chip-selected': zoomPercent === preset }" @click="setZoomPreset(preset)">
                {{ preset }}%
              </v-btn>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		name: "uc-request-sign-canvas",
  props: {
    fileUrl: { type: String, default: "" },
    signBoxes: { type: Array, default: function () { return []; } },
    activePage: { type: Number, default: 1 },
    selectedBoxId: { type: Number, default: 0 }
  },
  emits: ["update-active-page", "select-box"],
  data: function () {
    return {
      pdfDoc: null,
      pages: [],
      pageCount: 1,
      currentPage: 1,
      scale: 1,
      minScale: 0.4,
      maxScale: 3.5,
      zoomStep: 0.1,
      zoomPresets: [75, 100, 125, 150, 200],
      renderToken: 0,
      syncingScroll: false,
      thumbnails: {}
    };
  },
  computed: {
    pageOptions: function () {
      var output = [];
      var i = 0;
      for (i = 1; i <= Number(this.pageCount || 1); i += 1) output.push(i);
      return output;
    },
    zoomPercent: function () {
      return Math.round(Number(this.scale || 1) * 100);
    }
  },
  mounted: function () {
    this.currentPage = this.normalizePage(this.activePage);
    this.loadPdf();
  },
  beforeUnmount: function () {
    this.cleanupPdf();
  },
  methods: {
    getPdfPageSize: function (pageNo) {
      var self = this;
      var target = this.normalizePage(pageNo);
      if (!this.pdfDoc || !this.pdfDoc.getPage) return Promise.resolve(null);
      return this.pdfDoc.getPage(target).then(function (page) {
        var viewport = page.getViewport({ scale: 1 });
        return {
          pageNo: target,
          width: Number(viewport && viewport.width || 0) || 0,
          height: Number(viewport && viewport.height || 0) || 0,
          rotation: Number(page && page.rotate || 0) || 0
        };
      }).catch(function () {
        return null;
      });
    },
    getPdfJsLibUrl: function () {
      return "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.10.377/pdf.min.js";
    },
    getPdfJsWorkerUrl: function () {
      return "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.10.377/pdf.worker.min.js";
    },
    normalizePage: function (value) {
      var p = Number(value || 1);
      if (!p || p < 1) p = 1;
      return Math.trunc(p);
    },
    clamp: function (value, min, max) {
      var n = Number(value);
      if (Number.isNaN(n)) n = min;
      if (n < min) n = min;
      if (n > max) n = max;
      return Math.round(n * 100) / 100;
    },
    ensurePdfJs: function () {
      var self = this;
      return new Promise(function (resolve, reject) {
        if (window.pdfjsLib) {
          if (!window.pdfjsLib.GlobalWorkerOptions.workerSrc) {
            window.pdfjsLib.GlobalWorkerOptions.workerSrc = self.getPdfJsWorkerUrl();
          }
          resolve(window.pdfjsLib);
          return;
        }
        var script = document.createElement("script");
        script.src = self.getPdfJsLibUrl();
        script.onload = function () {
          window.pdfjsLib.GlobalWorkerOptions.workerSrc = self.getPdfJsWorkerUrl();
          resolve(window.pdfjsLib);
        };
        script.onerror = function () {
          reject(new Error("Không tải được pdf.js"));
        };
        document.head.appendChild(script);
      });
    },
    getAuthHeader: function () {
      var raw = "";
      if (window.UserUtil && window.UserUtil.getAuthHeader && window.UserUtil.getAuthToken) {
        raw = window.UserUtil.getAuthHeader(window.UserUtil.getAuthToken() || "");
      } else if (window.$awt) {
        raw = window.$awt;
      }
      return raw ? String(raw) : "";
    },
    fetchPdfBuffer: function () {
      var headers = {};
      var auth = this.getAuthHeader();
      if (auth) headers.authorization = auth;
      return fetch(this.fileUrl, {
        method: "GET",
        headers: headers,
        credentials: "include",
        cache: "no-store"
      }).then(function (res) {
        if (!res.ok) throw new Error("Không đọc được PDF");
        return res.arrayBuffer();
      });
    },
    extractFileIdFromUrl: function (url) {
      var raw = String(url || "");
      var match = raw.match(/\/FileData\/([A-Za-z0-9-]+)/i);
      if (match && match[1]) return match[1];
      return "";
    },
    normalizeBase64: function (value) {
      var raw = String(value || "").trim();
      if (!raw) return "";
      if (raw.indexOf("base64,") >= 0) raw = raw.split("base64,").pop() || "";
      return raw.replace(/\s+/g, "");
    },
    looksLikeBase64Pdf: function (value) {
      var normalized = this.normalizeBase64(value);
      if (!normalized) return false;
      return normalized.indexOf("JVBERi0") === 0;
    },
    looksLikeRawPdfText: function (value) {
      var raw = String(value || "");
      return raw.indexOf("%PDF-") === 0;
    },
    base64ToArrayBuffer: function (base64) {
      var bytes = atob(base64);
      var length = bytes.length;
      var arr = new Uint8Array(length);
      var i = 0;
      for (i = 0; i < length; i += 1) arr[i] = bytes.charCodeAt(i);
      return arr.buffer;
    },
    rawBinaryStringToArrayBuffer: function (raw) {
      var text = String(raw || "");
      var len = text.length;
      var bytes = new Uint8Array(len);
      var i = 0;
      for (i = 0; i < len; i += 1) bytes[i] = text.charCodeAt(i) & 0xff;
      return bytes.buffer;
    },
    parsePdfContentToArrayBuffer: function (value) {
      var raw = String(value || "");
      if (!raw) return null;
      if (this.looksLikeBase64Pdf(raw)) {
        return this.base64ToArrayBuffer(raw);
      }
      if (this.looksLikeRawPdfText(raw)) {
        return this.rawBinaryStringToArrayBuffer(raw);
      }
      return null;
    },
    fetchPdfBufferFromApi: async function () {
      var fileId = this.extractFileIdFromUrl(this.fileUrl);
      var rows = [];
      var row = null;
      var binary = "";
      var buffer = null;
      if (!fileId || typeof apiCallAsync !== "function") throw new Error("Không parse được FileID runtime.");
      rows = await apiCallAsync("FileData_GetByID", { FileID: fileId });
      row = rows && rows[0] ? rows[0] : null;
      binary = row && (row.BinaryContent || row.FILE_CONTENT || row.File_Binary || row.FILE_BINARY || row.FileBinaryBase64 || row.FileBinary || "");
      buffer = this.parsePdfContentToArrayBuffer(binary);
      if (!buffer) throw new Error("Không đọc được BinaryContent PDF của file runtime.");
      return buffer;
    },
    fetchPdfBufferSafe: async function () {
      try {
        return await this.fetchPdfBufferFromApi();
      } catch (err) {
        return this.fetchPdfBuffer();
      }
    },
    cleanupPdf: function () {
      this.renderToken += 1;
      this.clearPdfState();
    },
    clearPdfState: function () {
      if (this.pdfDoc && this.pdfDoc.destroy) {
        try { this.pdfDoc.destroy(); } catch (e) {}
      }
      this.pdfDoc = null;
      this.pages = [];
      this.thumbnails = {};
    },
    resolvePageCount: function (pdfCount) {
      var maxPage = Number(pdfCount || 1);
      var i = 0;
      for (i = 0; i < this.signBoxes.length; i += 1) {
        maxPage = Math.max(maxPage, this.normalizePage(this.signBoxes[i] && this.signBoxes[i].PageNo));
      }
      if (!maxPage || maxPage < 1) maxPage = 1;
      return maxPage;
    },
    loadPdf: function () {
      var self = this;
      var token = this.renderToken + 1;
      this.renderToken = token;
      if (!this.fileUrl) {
        this.cleanupPdf();
        this.pageCount = this.resolvePageCount(1);
        this.currentPage = this.normalizePage(this.activePage);
        return;
      }
      this.ensurePdfJs()
        .then(function (pdfjsLib) {
          return self.fetchPdfBufferSafe().then(function (buffer) {
            return pdfjsLib.getDocument({ data: buffer }).promise;
          });
        })
        .then(function (pdfDoc) {
          if (token !== self.renderToken) return;
          self.clearPdfState();
          self.pdfDoc = pdfDoc;
          return self.rebuildPages().then(function () {
            if (token !== self.renderToken) return;
            self.$nextTick(function () {
              self.paintPages(token);
              self.setPage(self.activePage, false);
            });
          });
        })
        .catch(function () {
          if (token !== self.renderToken) return;
          self.clearPdfState();
          self.pageCount = self.resolvePageCount(1);
          self.currentPage = self.normalizePage(self.activePage);
        });
    },
    rebuildPages: function () {
      var self = this;
      var rows = [];
      var chain = Promise.resolve();
      var pageNo = 1;
      if (!this.pdfDoc) {
        this.pages = [];
        this.pageCount = this.resolvePageCount(1);
        return Promise.resolve();
      }
      this.pageCount = this.resolvePageCount(Number(this.pdfDoc.numPages || 1));
      for (pageNo = 1; pageNo <= Number(this.pdfDoc.numPages || 0); pageNo += 1) {
        (function (currentPageNo) {
          chain = chain.then(function () {
            return self.pdfDoc.getPage(currentPageNo).then(function (page) {
              var viewport = page.getViewport({ scale: self.scale });
              var unscaledViewport = page.getViewport({ scale: 1 });
              rows.push({
                pageNo: currentPageNo,
                width: Math.round(viewport.width),
                height: Math.round(viewport.height),
                originalWidth: unscaledViewport.width || 595,
                originalHeight: unscaledViewport.height || 842
              });
            });
          });
        })(pageNo);
      }
      return chain.then(function () {
        self.pages = rows;
      });
    },
    paintPages: function (token) {
      var self = this;
      var pixelRatio = Math.max(window.devicePixelRatio || 1, 1);
      var pageNo = 1;
      if (!this.pdfDoc) return;
      for (pageNo = 1; pageNo <= Number(this.pdfDoc.numPages || 0); pageNo += 1) {
        (function (currentPageNo) {
          self.pdfDoc.getPage(currentPageNo).then(function (page) {
            var displayViewport = page.getViewport({ scale: self.scale });
            var renderViewport = page.getViewport({ scale: self.scale * pixelRatio });
            var canvas = document.getElementById("wf-request-page-" + currentPageNo);
            var ctx = canvas && canvas.getContext ? canvas.getContext("2d") : null;
            if (!canvas || !ctx || token !== self.renderToken) return;
            canvas.style.width = Math.round(displayViewport.width) + "px";
            canvas.style.height = Math.round(displayViewport.height) + "px";
            canvas.width = Math.round(renderViewport.width);
            canvas.height = Math.round(renderViewport.height);
            var task = page.render({ canvasContext: ctx, viewport: renderViewport });
            if (task && task.promise) {
              task.promise.then(function () {
                if (token !== self.renderToken) return;
                try {
                  var url = canvas.toDataURL("image/jpeg", 0.5);
                  var next = Object.assign({}, self.thumbnails);
                  next[currentPageNo] = url;
                  self.thumbnails = next;
                } catch (e) {}
              }).catch(function () {});
            }
          });
        })(pageNo);
      }
    },
    boxesByPage: function (pageNo) {
      var target = this.normalizePage(pageNo);
      return (this.signBoxes || []).filter(function (item) {
        return Number(item && item.PageNo || 1) === target;
      });
    },
    boxStyle: function (box) {
      var width = box && (box.BoxWidth != null ? box.BoxWidth : box.Width) || 0;
      var height = box && (box.BoxHeight != null ? box.BoxHeight : box.Height) || 0;
      var left = box && box.PosX || 0;
      var top = box && box.PosY || 0;

      var isPercent = left >= 0 && top >= 0 && width > 0 && height > 0 && left <= 100 && top <= 100 && width <= 100 && height <= 100;
      if (!isPercent) {
        var pageNo = this.normalizePage(box && box.PageNo || 1);
        var page = this.pages.find(function (p) { return p.pageNo === pageNo; });
        if (page && page.originalWidth && page.originalHeight) {
          left = (left / page.originalWidth) * 100;
          top = ((page.originalHeight - top - height) / page.originalHeight) * 100;
          width = (width / page.originalWidth) * 100;
          height = (height / page.originalHeight) * 100;
        }
      }

      width = this.clamp(width, 8, 65);
      height = this.clamp(height, 4, 35);
      left = this.clamp(left, 0, Math.max(0, 100 - width));
      top = this.clamp(top, 0, Math.max(0, 100 - height));
      return {
        left: left + "%",
        top: top + "%",
        width: width + "%",
        height: height + "%"
      };
    },
    boxLabel: function (box) {
      var order = Number(box && box.BoxOrder || 0);
      var name = box && (box.PersonName || box.SignerValue || box.LabelText) ? (box.PersonName || box.SignerValue || box.LabelText) : "Chưa gán";
      if (!order) order = 0;
      return "#" + order + " - " + name;
    },
    onSelectBox: function (box) {
      this.$emit("select-box", box);
      this.setPage(box && box.PageNo ? box.PageNo : this.currentPage, true);
    },
    prevPage: function () {
      this.setPage(this.currentPage - 1, true);
    },
    nextPage: function () {
      this.setPage(this.currentPage + 1, true);
    },
    applyScale: function (nextScale) {
      var self = this;
      var targetScale = this.clamp(nextScale, this.minScale, this.maxScale);
      var restorePage = this.currentPage || 1;
      if (Math.abs(targetScale - this.scale) < 0.001) return;
      this.scale = targetScale;
      this.renderToken += 1;
      var token = this.renderToken;
      this.rebuildPages().then(function () {
        if (token !== self.renderToken) return;
        self.$nextTick(function () {
          self.paintPages(token);
          self.setPage(restorePage, false);
        });
      });
    },
    zoomIn: function () {
      this.applyScale(Number(this.scale || 1) + this.zoomStep);
    },
    zoomOut: function () {
      this.applyScale(Number(this.scale || 1) - this.zoomStep);
    },
    setZoomPreset: function (preset) {
      this.applyScale(Number(preset || 100) / 100);
    },
    fitToViewport: function () {
      var self = this;
      var viewport = this.$refs.viewport;
      var pageNo = this.normalizePage(this.currentPage || 1);
      if (!this.pdfDoc || !viewport || !viewport.clientWidth) return;
      this.pdfDoc.getPage(pageNo).then(function (page) {
        var raw = page.getViewport({ scale: 1 });
        var availableWidth = Math.max(120, viewport.clientWidth - 24);
        var targetScale = availableWidth / Math.max(1, Number(raw.width || 1));
        self.applyScale(targetScale);
      });
    },
    setPage: function (pageNo, smooth) {
      var target = this.normalizePage(pageNo);
      var viewport = this.$refs.viewport;
      var pageEl = null;
      if (target > this.pageCount) target = this.pageCount;
      if (target < 1) target = 1;
      this.currentPage = target;
      this.$emit("update-active-page", target);
      if (!viewport) return;
      pageEl = viewport.querySelector('[data-page-no="' + target + '"]');
      if (!pageEl) return;
      this.syncingScroll = true;
      viewport.scrollTo({
        top: Math.max(0, pageEl.offsetTop - 10),
        behavior: smooth ? "smooth" : "auto"
      });
      window.setTimeout(this.releaseScrollSync, smooth ? 280 : 120);
    },
    focusBoxById: function (boxId, fallbackPageNo) {
      var viewport = this.$refs.viewport;
      var target = viewport ? viewport.querySelector('[data-box-id="' + Number(boxId || 0) + '"]') : null;
      var pageNo = this.normalizePage(fallbackPageNo || this.currentPage || 1);
      if (target && target.getBoundingClientRect) {
        this.syncingScroll = true;
        viewport.scrollTo({
          top: Math.max(0, target.offsetTop - 120),
          behavior: "smooth"
        });
        window.setTimeout(this.releaseScrollSync, 320);
        this.currentPage = pageNo;
        this.$emit("update-active-page", pageNo);
        return;
      }
      this.setPage(pageNo, true);
    },
    releaseScrollSync: function () {
      this.syncingScroll = false;
    },
    onScroll: function () {
      var viewport = this.$refs.viewport;
      var pages = viewport ? viewport.querySelectorAll(".wf-free-sign-page") : [];
      var nearest = 1;
      var i = 0;
      var distance = Number.MAX_SAFE_INTEGER;
      if (!viewport || this.syncingScroll) return;
      for (i = 0; i < pages.length; i += 1) {
        var diff = Math.abs(pages[i].offsetTop - viewport.scrollTop - 10);
        if (diff < distance) {
          distance = diff;
          nearest = this.normalizePage(pages[i].getAttribute("data-page-no"));
        }
      }
      this.currentPage = nearest;
      this.$emit("update-active-page", nearest);
    }
  },
  watch: {
    fileUrl: function () {
      this.loadPdf();
    },
    activePage: function (value) {
      var target = this.normalizePage(value);
      if (target === this.currentPage) return;
      this.setPage(target, false);
    },
    signBoxes: {
      deep: true,
      handler: function () {
        this.pageCount = this.resolvePageCount(this.pdfDoc ? this.pdfDoc.numPages : 1);
      }
    }
  }
	}
</script>