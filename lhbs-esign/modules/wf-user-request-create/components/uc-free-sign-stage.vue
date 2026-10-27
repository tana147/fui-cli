<template>
	<div class="wf-free-sign-canvas">
    <div ref="viewport" class="wf-free-sign-canvas__viewport" @scroll="onViewportScroll" @wheel="onViewportWheel">
      <div v-if="renderedPages.length > 0" class="wf-free-sign-pages">
        <div v-for="page in renderedPages" :key="'pdf-page-' + page.pageNo" class="wf-free-sign-page"
          :data-page-no="page.pageNo" :style="{ width: page.width + 'px', height: page.height + 'px' }">
          <canvas :id="'wf-free-sign-canvas-page-' + page.pageNo" class="wf-free-sign-page__canvas" :width="page.width"
            :height="page.height"></canvas>
          <div class="wf-free-sign-page__overlay" @click="$emit('canvas-click', page.pageNo, $event)">
            <div v-for="item in boxesForPage(page.pageNo)" :key="'box-' + page.pageNo + '-' + item.absoluteIndex"
              :data-box-index="item.absoluteIndex" class="wf-free-sign-box"
              :class="{ active: item.absoluteIndex === selectedBoxIndex }" :style="boxStyle(item.box)"
              @click.stop.prevent="$emit('select-box', item.absoluteIndex, { navigate: false })"
              @dblclick.stop.prevent="$emit('open-box-dialog', item.absoluteIndex)"
              @mousedown.stop.prevent="$emit('box-mouse-down', item.absoluteIndex, $event)"
              @touchstart.stop.prevent="$emit('box-touch-start', item.absoluteIndex, $event)">
              <button class="wf-free-sign-box__delete" type="button" @mousedown.stop.prevent @touchstart.stop.prevent
                @click.stop.prevent="$emit('remove-box', item.absoluteIndex)">
                <v-icon size="11">mdi-close</v-icon>
              </button>
              <span class="wf-free-sign-box__label">{{ boxLabel(item.box, item.absoluteIndex) }}</span>
              <span class="wf-free-sign-box__resize"
                @mousedown.stop.prevent="$emit('resize-handle-mouse-down', item.absoluteIndex, $event)"
                @touchstart.stop.prevent="$emit('resize-handle-touch-start', item.absoluteIndex, $event)"></span>
            </div>
          </div>
        </div>
      </div>

      <div v-else class="wf-free-sign-empty">
        <v-icon size="26" color="grey-lighten-1">mdi-file-pdf-box</v-icon>
        <div>Chưa có preview PDF. Bạn vẫn có thể đặt box theo tỷ lệ trang.</div>
      </div>
    </div>
    <div class="wf-free-sign-viewer-footer">
      <div class="wf-free-sign-viewer-footer__left">
        <span class="wf-free-sign-viewer-footer__meta">Trang {{ activePage }}/{{ effectivePageCount }}</span>
        <span class="wf-free-sign-viewer-footer__meta">Box ký: {{ signBoxes.length }}</span>
      </div>
      <div class="wf-free-sign-viewer-zoom">
        <v-btn variant="text" size="small" icon="mdi-minus" @click="$emit('zoom-out')"></v-btn>
        <div class="wf-free-sign-viewer-zoom__value">{{ zoomPercent }}%</div>
        <v-btn variant="text" size="small" icon="mdi-plus" @click="$emit('zoom-in')"></v-btn>
        <v-btn class="wf-btn" variant="text" color="primary" size="small" @click="$emit('fit-to-viewport')">
          <v-icon start size="14">mdi-fit-to-page-outline</v-icon>
          Vừa khung
        </v-btn>
        <div class="wf-free-sign-viewer-zoom__presets">
          <v-btn v-for="preset in zoomPresets" :key="'viewer-zoom-' + preset" variant="text" size="small"
            :class="{ 'wf-chip-selected': zoomPercent === preset }" @click="$emit('set-zoom-preset', preset)">
            {{ preset }}%
          </v-btn>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		name: "uc-free-sign-stage",
  props: {
    previewFileUrl: { type: String, default: "" },
    signBoxes: { type: Array, default: function () { return []; } },
    activePage: { type: Number, default: 1 },
    selectedBoxIndex: { type: Number, default: -1 },
    zoomPercent: { type: Number, default: 100 },
    zoomPresets: { type: Array, default: function () { return [75, 100, 125, 150, 200]; } },
    boxStyle: { type: Function, required: true },
    boxLabel: { type: Function, required: true }
  },
  emits: [
    "canvas-click",
    "select-box",
    "open-box-dialog",
    "box-mouse-down",
    "box-touch-start",
    "remove-box",
    "resize-handle-mouse-down",
    "resize-handle-touch-start",
    "zoom-out",
    "zoom-in",
    "fit-to-viewport",
    "set-zoom-preset",
    "update-page-count",
    "update-active-page",
    "update-thumbnails",
    "wheel-zoom-in",
    "wheel-zoom-out"
  ],
  data: function () {
    return {
      pdfDoc: null,
      renderedPages: [],
      effectivePageCount: 1,
      isSyncingScroll: false,
      renderToken: 0
    };
  },
  mounted: function () {
    this.renderDocument();
  },
  beforeUnmount: function () {
    this.cleanupPdf();
  },
  methods: {
    getPdfJsLibUrl: function () {
      return "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.10.377/pdf.min.js";
    },
    getPdfJsWorkerUrl: function () {
      return "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.10.377/pdf.worker.min.js";
    },
    getAuthHeader: function () {
      var raw = "";
      if (window.UserUtil && window.UserUtil.getAuthHeader && window.UserUtil.getAuthToken) {
        raw = window.UserUtil.getAuthHeader(window.UserUtil.getAuthToken() || "");
      }
      if (!raw && window.UserUtil && window.UserUtil.getAuthToken) {
        raw = window.UserUtil.getAuthToken() || "";
      }
      if (!raw && window.$awt) raw = window.$awt;
      if (!raw) return "";
      if (String(raw).toLowerCase().indexOf("bearer ") === 0) return raw;
      return raw;
    },
    fetchPdfBuffer: function (url) {
      var targetUrl = String(url || "");
      if (!targetUrl) return Promise.reject(new Error("Thiếu URL PDF."));
      if (targetUrl.indexOf("blob:") === 0 || targetUrl.indexOf("data:") === 0) {
        return fetch(targetUrl, { method: "GET", cache: "no-store" }).then(function (res) {
          if (!res.ok) throw new Error("Không đọc được file PDF: " + res.status);
          return res.arrayBuffer();
        });
      }
      var headers = {};
      var auth = this.getAuthHeader();
      if (auth) headers.authorization = auth;
      return fetch(targetUrl, {
        method: "GET",
        headers: headers,
        credentials: "include",
        cache: "no-store"
      }).then(function (res) {
        if (!res.ok) throw new Error("Không đọc được file PDF: " + res.status);
        return res.arrayBuffer();
      }).catch(function () {
        return fetch(targetUrl, {
          method: "GET",
          credentials: "include",
          cache: "no-store"
        }).then(function (res) {
          if (!res.ok) throw new Error("Không đọc được file PDF: " + res.status);
          return res.arrayBuffer();
        });
      });
    },
    normalizeBase64: function (value) {
      var raw = String(value || "").trim();
      if (!raw) return "";
      if (raw.indexOf("base64,") >= 0) raw = raw.split("base64,").pop() || "";
      return raw.replace(/\s+/g, "");
    },
    base64ToArrayBuffer: function (base64) {
      var normalized = this.normalizeBase64(base64);
      var bytes = atob(normalized);
      var len = bytes.length;
      var arr = new Uint8Array(len);
      var i = 0;
      for (i = 0; i < len; i += 1) arr[i] = bytes.charCodeAt(i);
      return arr.buffer;
    },
    rawBinaryStringToArrayBuffer: function (raw) {
      var text = String(raw || "");
      var len = text.length;
      var arr = new Uint8Array(len);
      var i = 0;
      for (i = 0; i < len; i += 1) arr[i] = text.charCodeAt(i) & 0xff;
      return arr.buffer;
    },
    hexToArrayBuffer: function (hex) {
      var normalized = String(hex || "").trim();
      var clean = normalized.indexOf("0x") === 0 || normalized.indexOf("0X") === 0 ? normalized.slice(2) : normalized;
      var len = 0;
      var arr = null;
      var i = 0;
      if (!clean || !/^[0-9a-fA-F]+$/.test(clean) || clean.length % 2 !== 0) return null;
      len = clean.length / 2;
      arr = new Uint8Array(len);
      for (i = 0; i < len; i += 1) arr[i] = parseInt(clean.substr(i * 2, 2), 16);
      return arr.buffer;
    },
    parsePdfContentToArrayBuffer: function (value) {
      var raw = String(value || "");
      var normalized = this.normalizeBase64(raw);
      if (!raw) return null;
      if (raw.indexOf("%PDF-") === 0) return this.rawBinaryStringToArrayBuffer(raw);
      if (raw.indexOf("0x") === 0 || raw.indexOf("0X") === 0) return this.hexToArrayBuffer(raw);
      try {
        if (/^[A-Za-z0-9+/=]+$/.test(normalized)) return this.base64ToArrayBuffer(normalized);
      } catch (e) {
      }
      if (raw.indexOf("%PDF-") > 0) return this.rawBinaryStringToArrayBuffer(raw.slice(raw.indexOf("%PDF-")));
      return null;
    },
    fetchPdfBufferByFileId: function (fileId) {
      var self = this;
      var normalized = String(fileId || "").trim();
      return new Promise(function (resolve, reject) {
        if (!normalized) {
          reject(new Error("Thiếu FileID."));
          return;
        }
        self.readFileBinaryById(normalized, function (payload) {
          var buffer = self.parsePdfContentToArrayBuffer(payload);
          if (!buffer) {
            self.fetchPdfBuffer("https://file.zentea.vn/iotdev/FileData/" + normalized)
              .then(resolve)
              .catch(function (err2) {
                reject(err2 || new Error("Không đọc được binary PDF theo FileID."));
              });
            return;
          }
          resolve(buffer);
        }, function (err) {
          self.fetchPdfBuffer("https://file.zentea.vn/iotdev/FileData/" + normalized)
            .then(resolve)
            .catch(function () {
              reject(err || new Error("FileData_GetByID failed."));
            });
        });
      });
    },
    readFileBinaryById: function (fileId, onSuccess, onError) {
      var normalized = String(fileId || "").trim();
      var handled = false;
      var finishSuccess = function (binary) {
        if (handled) return;
        handled = true;
        if (typeof onSuccess === "function") onSuccess(binary || "");
      };
      var finishError = function (err) {
        if (handled) return;
        handled = true;
        if (typeof onError === "function") onError(err || new Error("READ_FILE_FAILED"));
      };
      var pickBinary = function (res) {
        var row = null;
        if (res && res.data && res.data[0] && res.data[0][0]) row = res.data[0][0];
        else if (res && res[0]) row = res[0];
        else if (res && res.FileID) row = res;
        return row ? (row.BinaryContent || row.FILE_CONTENT || row.File_Binary || row.FILE_BINARY || row.FileBinaryBase64 || "") : "";
      };
      var readWithApiCallAsync = async function (apiName, payload) {
        if (typeof apiCallAsync !== "function") throw new Error("apiCallAsync unavailable");
        return apiCallAsync(apiName, payload || {});
      };
      if (!normalized) {
        finishError(new Error("MISSING_FILE_ID"));
        return;
      }
      (async function () {
        var res2 = null;
        var binary = "";
        try {
          res2 = await readWithApiCallAsync("FileData_GetByID", { FileID: normalized });
          binary = pickBinary(res2);
          finishSuccess(binary);
          return;
        } catch (e2) {
          finishError(e2);
          return;
        }
      })();
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
        var existed = document.getElementById("wf-pdfjs-lib");
        if (existed) {
          if (!window.pdfjsLib) existed.remove();
          else {
            existed.addEventListener("load", function () {
              if (window.pdfjsLib && !window.pdfjsLib.GlobalWorkerOptions.workerSrc) {
                window.pdfjsLib.GlobalWorkerOptions.workerSrc = self.getPdfJsWorkerUrl();
              }
              resolve(window.pdfjsLib);
            }, { once: true });
            existed.addEventListener("error", function () {
              reject(new Error("Không tải được pdf.js."));
            }, { once: true });
            return;
          }
        }
        var script = document.createElement("script");
        script.id = "wf-pdfjs-lib";
        script.src = self.getPdfJsLibUrl();
        script.onload = function () {
          if (window.pdfjsLib && !window.pdfjsLib.GlobalWorkerOptions.workerSrc) {
            window.pdfjsLib.GlobalWorkerOptions.workerSrc = self.getPdfJsWorkerUrl();
          }
          resolve(window.pdfjsLib);
        };
        script.onerror = function () {
          reject(new Error("Không tải được pdf.js."));
        };
        document.head.appendChild(script);
      });
    },
    resetPdfState: function () {
      if (this.pdfDoc && this.pdfDoc.destroy) {
        try { this.pdfDoc.destroy(); } catch (err) {}
      }
      this.pdfDoc = null;
      this.renderedPages = [];
      this.$emit("update-thumbnails", []);
    },
    cleanupPdf: function () {
      this.renderToken += 1;
      this.resetPdfState();
    },
    renderDocument: function () {
      var self = this;
      var token = this.renderToken + 1;
      var sourcePromise = null;
      this.renderToken = token;
      if (!this.previewFileUrl) {
        this.resetPdfState();
        this.effectivePageCount = this.maxPageFromBoxes();
        this.$emit("update-page-count", this.effectivePageCount);
        return;
      }
      sourcePromise = this.fetchPdfBuffer(this.previewFileUrl);
      this.ensurePdfJs().then(function (pdfjsLib) {
        return sourcePromise.then(function (buffer) {
          return pdfjsLib.getDocument({ data: buffer }).promise;
        });
      }).then(function (pdfDoc) {
        if (token !== self.renderToken) return;
        self.resetPdfState();
        self.pdfDoc = pdfDoc;
        self.effectivePageCount = Number(pdfDoc.numPages || 1) || 1;
        self.$emit("update-page-count", self.effectivePageCount);
        return self.renderAllPages(token);
      }).catch(function () {
        if (token !== self.renderToken) return;
        self.resetPdfState();
        self.effectivePageCount = self.maxPageFromBoxes();
        self.$emit("update-page-count", self.effectivePageCount);
      });
    },
    renderAllPages: function (token) {
      var self = this;
      var pages = [];
      var pageNo = 1;
      var scale = Number(this.zoomPercent || 100) / 100;
      var chain = Promise.resolve();
      for (pageNo = 1; pageNo <= this.effectivePageCount; pageNo += 1) {
        (function (currentPageNo) {
          chain = chain.then(function () {
            if (!self.pdfDoc || token !== self.renderToken) return;
            return self.pdfDoc.getPage(currentPageNo).then(function (page) {
              var viewport = page.getViewport({ scale: scale });
              pages.push({
                pageNo: currentPageNo,
                width: Math.round(viewport.width),
                height: Math.round(viewport.height)
              });
            });
          });
        })(pageNo);
      }
      return chain.then(function () {
        if (token !== self.renderToken) return;
        self.renderedPages = pages;
        return self.$nextTick(function () {
          self.paintAllCanvases(token);
          self.scrollToPage(self.activePage, false);
        });
      });
    },
    paintAllCanvases: function (token) {
      var self = this;
      var pageNo = 1;
      var scale = Number(this.zoomPercent || 100) / 100;
      var thumbnailRows = [];
      var pixelRatio = Math.max(window.devicePixelRatio || 1, 1);
      for (pageNo = 1; pageNo <= this.effectivePageCount; pageNo += 1) {
        (function (currentPageNo) {
          if (!self.pdfDoc || token !== self.renderToken) return;
          self.pdfDoc.getPage(currentPageNo).then(function (page) {
            var displayViewport = page.getViewport({ scale: scale });
            var renderViewport = page.getViewport({ scale: scale * pixelRatio });
            var canvas = document.getElementById("wf-free-sign-canvas-page-" + currentPageNo);
            var ctx = canvas && canvas.getContext ? canvas.getContext("2d") : null;
            if (!canvas || !ctx || token !== self.renderToken) return;
            canvas.style.width = Math.round(displayViewport.width) + "px";
            canvas.style.height = Math.round(displayViewport.height) + "px";
            canvas.width = Math.round(renderViewport.width);
            canvas.height = Math.round(renderViewport.height);
            ctx.setTransform(1, 0, 0, 1, 0, 0);
            page.render({ canvasContext: ctx, viewport: renderViewport }).promise.then(function () {
              if (token !== self.renderToken) return;
              thumbnailRows.push({
                pageNo: currentPageNo,
                dataUrl: self.buildThumbnailDataUrl(canvas)
              });
              if (thumbnailRows.length === self.effectivePageCount) {
                thumbnailRows.sort(function (a, b) { return a.pageNo - b.pageNo; });
                self.$emit("update-thumbnails", thumbnailRows);
              }
            });
          });
        })(pageNo);
      }
    },
    buildThumbnailDataUrl: function (sourceCanvas) {
      var thumbCanvas = document.createElement("canvas");
      var targetWidth = 86;
      var ratio = sourceCanvas.width > 0 ? (targetWidth / sourceCanvas.width) : 1;
      thumbCanvas.width = targetWidth;
      thumbCanvas.height = Math.max(1, Math.round(sourceCanvas.height * ratio));
      var ctx = thumbCanvas.getContext("2d");
      if (!ctx) return "";
      ctx.fillStyle = "#ffffff";
      ctx.fillRect(0, 0, thumbCanvas.width, thumbCanvas.height);
      ctx.drawImage(sourceCanvas, 0, 0, thumbCanvas.width, thumbCanvas.height);
      return thumbCanvas.toDataURL("image/jpeg", 0.82);
    },
    boxesForPage: function (pageNo) {
      var rows = [];
      var i = 0;
      for (i = 0; i < this.signBoxes.length; i += 1) {
        if (Number(this.signBoxes[i].PageNo || 1) === Number(pageNo || 1)) {
          rows.push({ absoluteIndex: i, box: this.signBoxes[i] });
        }
      }
      return rows;
    },
    maxPageFromBoxes: function () {
      var highest = 1;
      var i = 0;
      for (i = 0; i < this.signBoxes.length; i += 1) {
        highest = Math.max(highest, Number(this.signBoxes[i].PageNo || 1) || 1);
      }
      return highest;
    },
    scrollToPage: function (pageNo, smooth) {
      var viewport = this.$refs.viewport;
      var target = viewport ? viewport.querySelector('[data-page-no="' + Number(pageNo || 1) + '"]') : null;
      var viewportRect = null;
      var targetRect = null;
      if (!viewport || !target) return;
      viewportRect = viewport.getBoundingClientRect ? viewport.getBoundingClientRect() : null;
      targetRect = target.getBoundingClientRect ? target.getBoundingClientRect() : null;
      this.isSyncingScroll = true;
      viewport.scrollTo({
        top: Math.max(0, viewport.scrollTop + ((targetRect ? targetRect.top : target.offsetTop) - (viewportRect ? viewportRect.top : 0)) - 10),
        behavior: smooth === false ? "auto" : "smooth"
      });
      window.setTimeout(this.releaseScrollSync, 260);
    },
    scrollToBox: function (absoluteIndex) {
      var viewport = this.$refs.viewport;
      var box = viewport ? viewport.querySelector('[data-box-index="' + Number(absoluteIndex) + '"]') : null;
      if (!viewport || !box || !box.getBoundingClientRect) return;
      var viewportRect = viewport.getBoundingClientRect();
      var boxRect = box.getBoundingClientRect();
      this.isSyncingScroll = true;
      viewport.scrollTo({
        top: Math.max(0, viewport.scrollTop + (boxRect.top - viewportRect.top) - Math.max(40, (viewportRect.height * 0.25))),
        behavior: "smooth"
      });
      window.setTimeout(this.releaseScrollSync, 320);
    },
    releaseScrollSync: function () {
      this.isSyncingScroll = false;
    },
    onViewportScroll: function () {
      var viewport = this.$refs.viewport;
      var pages = viewport ? viewport.querySelectorAll(".wf-free-sign-page") : [];
      var current = 1;
      var i = 0;
      var pageNo = 1;
      var bestDistance = Number.MAX_SAFE_INTEGER;
      if (!viewport || this.isSyncingScroll) return;
      for (i = 0; i < pages.length; i += 1) {
        pageNo = Number(pages[i].getAttribute("data-page-no") || 1) || 1;
        var distance = Math.abs(pages[i].offsetTop - viewport.scrollTop - 10);
        if (distance < bestDistance) {
          bestDistance = distance;
          current = pageNo;
        }
      }
      this.$emit("update-active-page", current);
    },
    onViewportWheel: function (event) {
      if (!event || (!event.ctrlKey && !event.metaKey)) return;
      event.preventDefault();
      if (event.deltaY < 0) this.$emit("wheel-zoom-in");
      else this.$emit("wheel-zoom-out");
    },
    getPageRect: function (pageNo) {
      var viewport = this.$refs.viewport;
      var target = viewport ? viewport.querySelector('[data-page-no="' + Number(pageNo || 1) + '"]') : null;
      return target && target.getBoundingClientRect ? target.getBoundingClientRect() : null;
    }
  },
  watch: {
    previewFileUrl: function () {
      this.renderDocument();
    },
    zoomPercent: function () {
      this.renderDocument();
    },
    signBoxes: {
      deep: true,
      handler: function () {
        if (!this.previewFileUrl) {
          this.effectivePageCount = this.maxPageFromBoxes();
          this.$emit("update-page-count", this.effectivePageCount);
        }
      }
    }
  }
	}
</script>