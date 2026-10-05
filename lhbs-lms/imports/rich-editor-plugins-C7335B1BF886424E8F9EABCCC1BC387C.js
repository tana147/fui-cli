(function (global) {
    var plugins = {};

    function register(name, plugin) {
        if (!name || !plugin) return;
        plugins[name] = plugin;
    }

    function getFileIds(html) {
        var div = document.createElement('div');
        div.innerHTML = html || '';
        return Array.prototype.map.call(div.querySelectorAll('img'), function (img) {
            var src = img.getAttribute('src') || img.src || '';
            var marker = '/FileData/';
            var markerIndex = src.toLowerCase().indexOf(marker.toLowerCase());
            if (markerIndex < 0) return null;
            return src.slice(markerIndex + marker.length).split('?')[0].split('#')[0].split('"')[0].split("'")[0].split('/')[0] || null;
        }).filter(Boolean);
    }

    function deleteRemovedFiles(oldHtml, newHtml, hooks) {
        var oldIds = getFileIds(oldHtml);
        var newIds = getFileIds(newHtml);
        oldIds.filter(function (fileId, index) {
            return oldIds.indexOf(fileId) === index && newIds.indexOf(fileId) === -1;
        }).forEach(function (fileId) {
            var manager = global.UploadManager;
            if (!manager || !manager.deleteLmsFileData) return;
            manager.deleteLmsFileData(fileId, {
                onComplete: function (response) { if (hooks && hooks.onComplete) hooks.onComplete(fileId); },
                onError: function (error) { if (hooks && hooks.onError) hooks.onError(fileId, error); }
            });
        });
    }

    function ensureJSZip() {
        if (global.JSZip) return Promise.resolve();
        return new Promise(function (resolve, reject) {
            var script = document.createElement('script');
            script.src = 'https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js';
            script.onload = resolve; script.onerror = reject; document.head.appendChild(script);
        });
    }

    function ensureDeployGGB() {
        if (global.GGBApplet) return Promise.resolve();
        return new Promise(function (resolve, reject) {
            if (document.getElementById('deployggb-script')) {
                var check = setInterval(function () {
                    if (global.GGBApplet) { clearInterval(check); resolve(); }
                }, 100);
                return;
            }
            var script = document.createElement('script');
            script.id = 'deployggb-script';
            script.src = 'https://www.geogebra.org/apps/deployggb.js';
            script.onload = resolve;
            script.onerror = reject;
            document.head.appendChild(script);
        });
    }

    function fileToBase64(file) {
        return new Promise(function (resolve, reject) {
            var reader = new FileReader();
            reader.onload = function () {
                var result = reader.result || '';
                var base64 = result.indexOf(',') >= 0 ? result.split(',')[1] : result;
                resolve(base64);
            };
            reader.onerror = reject;
            reader.readAsDataURL(file);
        });
    }

    function cropThumbnail(srcUrl) {
        return new Promise(function (resolve, reject) {
            var image = new Image(); image.crossOrigin = 'anonymous';
            image.onload = function () {
                var canvas = document.createElement('canvas'), context = canvas.getContext('2d');
                var width = Math.max(0, image.width - 85); canvas.width = width; canvas.height = image.height;
                context.drawImage(image, 0, 0, width, image.height, 0, 0, width, image.height);
                canvas.toBlob(function (blob) { blob ? resolve(blob) : reject(new Error('Không tạo được ảnh thumbnail')); }, 'image/png');
            }; image.onerror = reject; image.src = srcUrl;
        });
    }

    function initInteractiveGeoGebra(rootElement) {
        var root = rootElement || document;
        var selector = 'img[alt*="GGB"]:not([data-ggb-injected="true"]), img[data-ggb-url]:not([data-ggb-injected="true"])';
        var imgs = root.querySelectorAll(selector);
        if (!imgs || imgs.length === 0) return;

        ensureDeployGGB().then(function () {
            imgs.forEach(function (img) {
                var alt = img.getAttribute('alt') || '';
                var base64 = img.getAttribute('data-ggb-base64');
                var ggbUrl = img.getAttribute('data-ggb-url');

                if (alt.indexOf('GGB_BASE64:') >= 0) {
                    var matchB64 = alt.match(/GGB_BASE64:([^\s"]+)/);
                    if (matchB64 && matchB64[1]) {
                        var targetVal = matchB64[1];
                        if (targetVal.indexOf('http') === 0 || targetVal.indexOf('/FileData/') >= 0) {
                            ggbUrl = targetVal;
                        } else {
                            base64 = targetVal;
                        }
                    }
                } else if (alt.indexOf('GGB:') >= 0) {
                    var matchUrl = alt.match(/GGB:([^\s"]+)/);
                    if (matchUrl && matchUrl[1]) ggbUrl = matchUrl[1];
                }

                if (!ggbUrl && !base64) {
                    var src = img.getAttribute('src') || '';
                    if (src.indexOf('/FileData/') >= 0 || src.indexOf('.ggb') >= 0) {
                        ggbUrl = src;
                    }
                }

                if (!ggbUrl && !base64) return;
                img.setAttribute('data-ggb-injected', 'true');

                var containerId = 'ggb_app_' + Math.random().toString(36).substring(2, 9);
                var wrapper = document.createElement('div');
                wrapper.className = 'uc-geogebra-player-container my-4';
                wrapper.style.cssText = 'width:100%; max-width:850px; height:500px; margin:16px auto; border-radius:8px; overflow:hidden; border:1px solid #e2e8f0; box-shadow:0 4px 12px rgba(0,0,0,0.08); position:relative;';

                var appletContainer = document.createElement('div');
                appletContainer.id = containerId;
                appletContainer.style.cssText = 'width:100%; height:500px;';

                wrapper.appendChild(appletContainer);

                if (img.parentNode) {
                    img.parentNode.insertBefore(wrapper, img);
                    img.style.display = 'none';
                }

                var width = wrapper.clientWidth || 800;
                var height = wrapper.clientHeight || 500;

                function renderAppletWithBase64(b64) {
                    var params = {
                        "appName": "classic",
                        "width": width,
                        "height": height,
                        "showToolBar": false,
                        "showAlgebraInput": false,
                        "showMenuBar": false,
                        "ggbBase64": b64,
                        "enableShiftDragZoom": true,
                        "showResetIcon": true
                    };
                    var applet = new global.GGBApplet(params, true);
                    applet.inject(containerId);
                }

                if (base64) {
                    renderAppletWithBase64(base64);
                } else if (ggbUrl) {
                    fetch(ggbUrl)
                        .then(function (res) { return res.arrayBuffer(); })
                        .then(function (buf) {
                            var bytes = new Uint8Array(buf);
                            if (bytes.length > 4 && bytes[0] === 80 && bytes[1] === 75) {
                                var binary = '';
                                var len = bytes.byteLength;
                                for (var i = 0; i < len; i++) {
                                    binary += String.fromCharCode(bytes[i]);
                                }
                                var b64 = global.btoa(binary);
                                renderAppletWithBase64(b64);
                            } else {
                                console.warn('[GeoGebra] Target URL is a static PNG image, keeping preview.');
                                img.style.display = 'block';
                                wrapper.remove();
                            }
                        })
                        .catch(function (err) {
                            console.warn('[GeoGebra] Fallback to static img:', err);
                            img.style.display = 'block';
                            wrapper.remove();
                        });
                } else {
                    img.style.display = 'block';
                    wrapper.remove();
                }
            });
        }).catch(function (err) {
            console.warn('[GeoGebra] Failed to load deployggb.js:', err);
        });
    }

    function processGgb(file, hooks) {
        fileToBase64(file).then(function(ggbBase64) {
            ensureJSZip().then(function () { return global.JSZip.loadAsync(file); })
                .then(function (zip) {
                    var thumbnail = zip.file('geogebra_thumbnail.png');
                    if (!thumbnail) {
                        var matches = zip.file(/thumbnail/i);
                        if (matches && matches.length > 0) thumbnail = matches[0];
                    }
                    if (!thumbnail) {
                        var pngFiles = zip.file(/\.png$/i);
                        if (pngFiles && pngFiles.length > 0) thumbnail = pngFiles[0];
                    }
                    if (!thumbnail) {
                        var jpgFiles = zip.file(/\.(jpg|jpeg)$/i);
                        if (jpgFiles && jpgFiles.length > 0) thumbnail = jpgFiles[0];
                    }
                    if (!thumbnail) return null;
                    return thumbnail.async('base64');
                })
                .then(function (base64) {
                    if (!base64) return null;
                    return cropThumbnail('data:image/png;base64,' + base64);
                })
                .then(function (pngBlob) {
                    if (pngBlob) {
                        var pngFileName = file.name.toLowerCase().endsWith('.ggb') ? file.name.slice(0, -4) + '_thumb.png' : file.name + '_thumb.png';
                        var pngFile = new File([pngBlob], pngFileName, { type: 'image/png' });
                        var baseUrl = (typeof vueData !== 'undefined' && vueData.v_Set && vueData.v_Set.urlReturnFile) || 'https://file.lhbs.vn/lms';
                        if (global.UploadManager && global.UploadManager.uploadLmsSharedFile) {
                            global.UploadManager.uploadLmsSharedFile(pngFile, {
                                onComplete: function (pngRes) {
                                    var pngItem = pngRes && pngRes.Files && pngRes.Files[0] ? pngRes.Files[0] : pngRes;
                                    var pngUrl = pngItem && pngItem.FILE_URL ? pngItem.FILE_URL : '';
                                    var finalPngUrl = pngUrl ? (pngUrl.indexOf('http') === 0 ? pngUrl : baseUrl + (pngUrl.indexOf('/') === 0 ? pngUrl : '/' + pngUrl)) : pngItem && pngItem.FILE_ID ? baseUrl + '/FileData/' + pngItem.FILE_ID : pngRes && pngRes.url ? pngRes.url : '';
                                    finishGgbUpload(finalPngUrl, ggbBase64, hooks);
                                },
                                onError: function () {
                                    finishGgbUpload('', ggbBase64, hooks);
                                }
                            });
                        } else {
                            finishGgbUpload('', ggbBase64, hooks);
                        }
                    } else {
                        finishGgbUpload('', ggbBase64, hooks);
                    }
                })
                .catch(function () {
                    finishGgbUpload('', ggbBase64, hooks);
                });
        }).catch(function(err) {
            if (hooks && hooks.onError) hooks.onError(err);
        });
    }

    function finishGgbUpload(pngUrl, ggbBase64, hooks) {
        if (hooks && hooks.insertImage) {
            hooks.insertImage(pngUrl, ggbBase64);
        }
        if (hooks && hooks.onComplete) hooks.onComplete();
    }

    global.RichTextEditorPlugins = {
        register: register,
        get: function (name) { return plugins[name]; },
        all: function () { return plugins; },
        getFileIds: getFileIds,
        deleteRemovedFiles: deleteRemovedFiles,
        initInteractiveGeoGebra: initInteractiveGeoGebra,
        process: function (name, file, hooks) { if (name === 'ggb') processGgb(file, hooks); }
    };
    ensureJSZip();
    ensureDeployGGB();
})(window);
