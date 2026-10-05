<template>
	<div ref="contentContainer" class="uc-latex-view" style="min-width: 0; overflow-x: visible;" v-html="renderedContent" />
</template>

<script>
	export default {
		props: {
        content: {
            // Dữ liệu cũ là chuỗi; một số API/import mới có thể bọc nội dung trong
            // object hoặc JSON string. Chấp nhận các dạng đó để renderer tự chuẩn hóa.
            type: [String, Number, Boolean, Object, Array],
            default: ''
        },
        escapeHtml: {
            type: Boolean,
            default: true  // Mặc định là escape để an toàn
        },
        literalHtmlTags: {
            type: Boolean,
            default: false
        },
        preserveHtmlStructure: {
            type: Boolean,
            default: false
        }
    },
    data() {
        return {
            renderedContent: '',
            renderVersion: 0
        }
    },
    watch: {
        content: {
            handler(newContent) {
                this.renderContent(newContent)
            },
            immediate: true
        },
        escapeHtml: {
            handler() {
                this.renderContent(this.content)
            }
        },
        literalHtmlTags: {
            handler() {
                this.renderContent(this.content)
            }
        },
        preserveHtmlStructure: {
            handler() {
                this.renderContent(this.content)
            }
        }
    },
    mounted() {
        this.setupMathJax()
            .then(() => this.typesetMath())
            .catch(err => console.error('MathJax setup error:', err))
    },
    methods: {
        normalizeRenderableContent(value) {
            if (value === null || value === undefined) return ''

            if (typeof value === 'string') {
                const trimmed = value.trim()
                // Một số bản ghi trả nội dung rich-text dưới dạng JSON string.
                // Chỉ parse khi chuỗi có hình dạng JSON và luôn fallback về chuỗi gốc.
                if ((trimmed.startsWith('{') || trimmed.startsWith('[')) && trimmed.length > 1) {
                    try {
                        const parsed = JSON.parse(trimmed)
                        if (parsed !== value) return this.normalizeRenderableContent(parsed)
                    } catch (_) {
                        // Chuỗi HTML/LaTeX thông thường có thể bắt đầu bằng ký tự này.
                    }
                }
                return value
            }

            if (Array.isArray(value)) {
                return value
                    .map(item => this.normalizeRenderableContent(item))
                    .filter(Boolean)
                    .join('')
            }

            if (typeof value === 'object') {
                // Hỗ trợ các wrapper thường gặp từ rich-text editor/API mà không để
                // Object.prototype.toString() biến nội dung thành "[object Object]".
                const contentKeys = ['html', 'content', 'text', 'value', 'questionText', 'data']
                for (const key of contentKeys) {
                    if (Object.prototype.hasOwnProperty.call(value, key)) {
                        return this.normalizeRenderableContent(value[key])
                    }
                }

                // Tương thích tối thiểu với Quill Delta nếu dữ liệu được lưu theo ops.
                if (Array.isArray(value.ops)) {
                    return value.ops
                        .map(op => typeof op?.insert === 'string' ? op.insert : '')
                        .join('')
                }
            }

            return typeof value === 'object' ? '' : String(value)
        },

        sanitizeLessonHtml(content) {
            return String(content || '')
                .replace(/<(script|style|iframe|object|embed|link|meta|base|form|input|button|textarea|select|option)\b[^>]*>[\s\S]*?<\/\1\s*>/gi, '')
                .replace(/<(script|style|iframe|object|embed|link|meta|base|form|input|button|textarea|select|option)\b[^>]*\/?>/gi, '')
                .replace(/\son[a-z]+\s*=\s*(?:"[^"]*"|'[^']*'|[^\s>]+)/gi, '')
                .replace(/\s(href|src)\s*=\s*(["'])\s*(?:javascript|vbscript):[\s\S]*?\2/gi, ' $1="#"')
                .replace(/\s(href|src)\s*=\s*(?:javascript|vbscript):[^\s>]*/gi, ' $1="#"')
        },

        escapeHtmlTags(content) {
            return content
                // Document metadata
                .replace(/<head/gi, '&lt;head')
                .replace(/<\/head>/gi, '&lt;/head&gt;')
                .replace(/<title/gi, '&lt;title')
                .replace(/<\/title>/gi, '&lt;/title&gt;')
                .replace(/<base/gi, '&lt;base')
                .replace(/<link/gi, '&lt;link')
                .replace(/<meta/gi, '&lt;meta')
                .replace(/<style/gi, '&lt;style')
                .replace(/<\/style>/gi, '&lt;/style&gt;')
                
                // Scripting
                .replace(/<script/gi, '&lt;script')
                .replace(/<\/script>/gi, '&lt;/script&gt;')
                .replace(/<noscript/gi, '&lt;noscript')
                .replace(/<\/noscript>/gi, '&lt;/noscript&gt;')
                
                // Sections
                .replace(/<body/gi, '&lt;body')
                .replace(/<\/body>/gi, '&lt;/body&gt;')
                .replace(/<article/gi, '&lt;article')
                .replace(/<\/article>/gi, '&lt;/article&gt;')
                .replace(/<section/gi, '&lt;section')
                .replace(/<\/section>/gi, '&lt;/section&gt;')
                .replace(/<nav/gi, '&lt;nav')
                .replace(/<\/nav>/gi, '&lt;/nav&gt;')
                .replace(/<aside/gi, '&lt;aside')
                .replace(/<\/aside>/gi, '&lt;/aside&gt;')
                .replace(/<header/gi, '&lt;header')
                .replace(/<\/header>/gi, '&lt;/header&gt;')
                .replace(/<footer/gi, '&lt;footer')
                .replace(/<\/footer>/gi, '&lt;/footer&gt;')
                .replace(/<main/gi, '&lt;main')
                .replace(/<\/main>/gi, '&lt;/main&gt;')
                
                // Grouping content
                .replace(/<div/gi, '&lt;div')
                .replace(/<\/div>/gi, '&lt;/div&gt;')
                .replace(/<p/gi, '&lt;p')
                .replace(/<\/p>/gi, '&lt;/p&gt;')
                .replace(/<hr/gi, '&lt;hr')
                .replace(/<pre/gi, '&lt;pre')
                .replace(/<\/pre>/gi, '&lt;/pre&gt;')
                .replace(/<blockquote/gi, '&lt;blockquote')
                .replace(/<\/blockquote>/gi, '&lt;/blockquote&gt;')
                .replace(/<ol/gi, '&lt;ol')
                .replace(/<\/ol>/gi, '&lt;/ol&gt;')
                .replace(/<ul/gi, '&lt;ul')
                .replace(/<\/ul>/gi, '&lt;/ul&gt;')
                .replace(/<li/gi, '&lt;li')
                .replace(/<\/li>/gi, '&lt;/li&gt;')
                .replace(/<dl/gi, '&lt;dl')
                .replace(/<\/dl>/gi, '&lt;/dl&gt;')
                .replace(/<dt/gi, '&lt;dt')
                .replace(/<\/dt>/gi, '&lt;/dt&gt;')
                .replace(/<dd/gi, '&lt;dd')
                .replace(/<\/dd>/gi, '&lt;/dd&gt;')
                .replace(/<figure/gi, '&lt;figure')
                .replace(/<\/figure>/gi, '&lt;/figure&gt;')
                .replace(/<figcaption/gi, '&lt;figcaption')
                .replace(/<\/figcaption>/gi, '&lt;/figcaption&gt;')
                
                // Text-level semantics
                .replace(/<a/gi, '&lt;a')
                .replace(/<\/a>/gi, '&lt;/a&gt;')
                .replace(/<em/gi, '&lt;em')
                .replace(/<\/em>/gi, '&lt;/em&gt;')
                .replace(/<strong/gi, '&lt;strong')
                .replace(/<\/strong>/gi, '&lt;/strong&gt;')
                .replace(/<small/gi, '&lt;small')
                .replace(/<\/small>/gi, '&lt;/small&gt;')
                .replace(/<s/gi, '&lt;s')
                .replace(/<\/s>/gi, '&lt;/s&gt;')
                .replace(/<cite/gi, '&lt;cite')
                .replace(/<\/cite>/gi, '&lt;/cite&gt;')
                .replace(/<q/gi, '&lt;q')
                .replace(/<\/q>/gi, '&lt;/q&gt;')
                .replace(/<dfn/gi, '&lt;dfn')
                .replace(/<\/dfn>/gi, '&lt;/dfn&gt;')
                .replace(/<abbr/gi, '&lt;abbr')
                .replace(/<\/abbr>/gi, '&lt;/abbr&gt;')
                .replace(/<data/gi, '&lt;data')
                .replace(/<\/data>/gi, '&lt;/data&gt;')
                .replace(/<time/gi, '&lt;time')
                .replace(/<\/time>/gi, '&lt;/time&gt;')
                .replace(/<code/gi, '&lt;code')
                .replace(/<\/code>/gi, '&lt;/code&gt;')
                .replace(/<var/gi, '&lt;var')
                .replace(/<\/var>/gi, '&lt;/var&gt;')
                .replace(/<samp/gi, '&lt;samp')
                .replace(/<\/samp>/gi, '&lt;/samp&gt;')
                .replace(/<kbd/gi, '&lt;kbd')
                .replace(/<\/kbd>/gi, '&lt;/kbd&gt;')
                .replace(/<sub/gi, '&lt;sub')
                .replace(/<\/sub>/gi, '&lt;/sub&gt;')
                .replace(/<sup/gi, '&lt;sup')
                .replace(/<\/sup>/gi, '&lt;/sup&gt;')
                .replace(/<i/gi, '&lt;i')
                .replace(/<\/i>/gi, '&lt;/i&gt;')
                .replace(/<b/gi, '&lt;b')
                .replace(/<\/b>/gi, '&lt;/b&gt;')
                .replace(/<u/gi, '&lt;u')
                .replace(/<\/u>/gi, '&lt;/u&gt;')
                .replace(/<mark/gi, '&lt;mark')
                .replace(/<\/mark>/gi, '&lt;/mark&gt;')
                .replace(/<ruby/gi, '&lt;ruby')
                .replace(/<\/ruby>/gi, '&lt;/ruby&gt;')
                .replace(/<rt/gi, '&lt;rt')
                .replace(/<\/rt>/gi, '&lt;/rt&gt;')
                .replace(/<rp/gi, '&lt;rp')
                .replace(/<\/rp>/gi, '&lt;/rp&gt;')
                .replace(/<bdi/gi, '&lt;bdi')
                .replace(/<\/bdi>/gi, '&lt;/bdi&gt;')
                .replace(/<bdo/gi, '&lt;bdo')
                .replace(/<\/bdo>/gi, '&lt;/bdo&gt;')
                .replace(/<span/gi, '&lt;span')
                .replace(/<\/span>/gi, '&lt;/span&gt;')
                .replace(/<br/gi, '&lt;br')
                .replace(/<wbr/gi, '&lt;wbr')
                
                // Edits
                .replace(/<ins/gi, '&lt;ins')
                .replace(/<\/ins>/gi, '&lt;/ins&gt;')
                .replace(/<del/gi, '&lt;del')
                .replace(/<\/del>/gi, '&lt;/del&gt;')
                
                // Embedded content
                .replace(/<img/gi, '&lt;img')
                .replace(/<iframe/gi, '&lt;iframe')
                .replace(/<\/iframe>/gi, '&lt;/iframe&gt;')
                .replace(/<embed/gi, '&lt;embed')
                .replace(/<object/gi, '&lt;object')
                .replace(/<\/object>/gi, '&lt;/object&gt;')
                .replace(/<param/gi, '&lt;param')
                .replace(/<video/gi, '&lt;video')
                .replace(/<\/video>/gi, '&lt;/video&gt;')
                .replace(/<audio/gi, '&lt;audio')
                .replace(/<\/audio>/gi, '&lt;/audio&gt;')
                .replace(/<source/gi, '&lt;source')
                .replace(/<track/gi, '&lt;track')
                .replace(/<canvas/gi, '&lt;canvas')
                .replace(/<\/canvas>/gi, '&lt;/canvas&gt;')
                .replace(/<map/gi, '&lt;map')
                .replace(/<\/map>/gi, '&lt;/map&gt;')
                .replace(/<area/gi, '&lt;area')
                .replace(/<svg/gi, '&lt;svg')
                .replace(/<\/svg>/gi, '&lt;/svg&gt;')
                
                // Tabular data
                .replace(/<table/gi, '&lt;table')
                .replace(/<\/table>/gi, '&lt;/table&gt;')
                .replace(/<caption/gi, '&lt;caption')
                .replace(/<\/caption>/gi, '&lt;/caption&gt;')
                .replace(/<colgroup/gi, '&lt;colgroup')
                .replace(/<\/colgroup>/gi, '&lt;/colgroup&gt;')
                .replace(/<col/gi, '&lt;col')
                .replace(/<tbody/gi, '&lt;tbody')
                .replace(/<\/tbody>/gi, '&lt;/tbody&gt;')
                .replace(/<thead/gi, '&lt;thead')
                .replace(/<\/thead>/gi, '&lt;/thead&gt;')
                .replace(/<tfoot/gi, '&lt;tfoot')
                .replace(/<\/tfoot>/gi, '&lt;/tfoot&gt;')
                .replace(/<tr/gi, '&lt;tr')
                .replace(/<\/tr>/gi, '&lt;/tr&gt;')
                .replace(/<td/gi, '&lt;td')
                .replace(/<\/td>/gi, '&lt;/td&gt;')
                .replace(/<th/gi, '&lt;th')
                .replace(/<\/th>/gi, '&lt;/th&gt;')
                
                // Forms
                .replace(/<form/gi, '&lt;form')
                .replace(/<\/form>/gi, '&lt;/form&gt;')
                .replace(/<label/gi, '&lt;label')
                .replace(/<\/label>/gi, '&lt;/label&gt;')
                .replace(/<input/gi, '&lt;input')
                .replace(/<button/gi, '&lt;button')
                .replace(/<\/button>/gi, '&lt;/button&gt;')
                .replace(/<select/gi, '&lt;select')
                .replace(/<\/select>/gi, '&lt;/select&gt;')
                .replace(/<datalist/gi, '&lt;datalist')
                .replace(/<\/datalist>/gi, '&lt;/datalist&gt;')
                .replace(/<optgroup/gi, '&lt;optgroup')
                .replace(/<\/optgroup>/gi, '&lt;/optgroup&gt;')
                .replace(/<option/gi, '&lt;option')
                .replace(/<\/option>/gi, '&lt;/option&gt;')
                .replace(/<textarea/gi, '&lt;textarea')
                .replace(/<\/textarea>/gi, '&lt;/textarea&gt;')
                .replace(/<output/gi, '&lt;output')
                .replace(/<\/output>/gi, '&lt;/output&gt;')
                .replace(/<progress/gi, '&lt;progress')
                .replace(/<\/progress>/gi, '&lt;/progress&gt;')
                .replace(/<meter/gi, '&lt;meter')
                .replace(/<\/meter>/gi, '&lt;/meter&gt;')
                .replace(/<fieldset/gi, '&lt;fieldset')
                .replace(/<\/fieldset>/gi, '&lt;/fieldset&gt;')
                .replace(/<legend/gi, '&lt;legend')
                .replace(/<\/legend>/gi, '&lt;/legend&gt;')
                
                // Interactive elements
                .replace(/<details/gi, '&lt;details')
                .replace(/<\/details>/gi, '&lt;/details&gt;')
                .replace(/<summary/gi, '&lt;summary')
                .replace(/<\/summary>/gi, '&lt;/summary&gt;')
                .replace(/<dialog/gi, '&lt;dialog')
                .replace(/<\/dialog>/gi, '&lt;/dialog&gt;')
                
                // Headings
                .replace(/<h1/gi, '&lt;h1')
                .replace(/<\/h1>/gi, '&lt;/h1&gt;')
                .replace(/<h2/gi, '&lt;h2')
                .replace(/<\/h2>/gi, '&lt;/h2&gt;')
                .replace(/<h3/gi, '&lt;h3')
                .replace(/<\/h3>/gi, '&lt;/h3&gt;')
                .replace(/<h4/gi, '&lt;h4')
                .replace(/<\/h4>/gi, '&lt;/h4&gt;')
                .replace(/<h5/gi, '&lt;h5')
                .replace(/<\/h5>/gi, '&lt;/h5&gt;')
                .replace(/<h6/gi, '&lt;h6')
                .replace(/<\/h6>/gi, '&lt;/h6&gt;')
                .replace(/<hgroup/gi, '&lt;hgroup')
                .replace(/<\/hgroup>/gi, '&lt;/hgroup&gt;')
                
                // Other
                .replace(/<html/gi, '&lt;html')
                .replace(/<\/html>/gi, '&lt;/html&gt;')
                .replace(/<address/gi, '&lt;address')
                .replace(/<\/address>/gi, '&lt;/address&gt;')
                .replace(/<template/gi, '&lt;template')
                .replace(/<\/template>/gi, '&lt;/template&gt;')
                .replace(/<slot/gi, '&lt;slot')
                .replace(/<\/slot>/gi, '&lt;/slot&gt;');
        },

        escapeAllHtmlTags(content) {
            // Chế độ này dành cho dữ liệu câu hỏi/đáp án: mọi thẻ HTML trong nội dung nguồn phải hiện như chữ,
            // nhưng vẫn giữ các delimiter LaTeX để MathJax xử lý công thức sau đó.
            return String(content || '').replace(/<!--[\s\S]*?-->|<!DOCTYPE[^>]*>|<\/?[A-Za-z][^>]*>/gi, tag => tag.replace(/</g, '&lt;').replace(/>/g, '&gt;'))
        },

        preserveEditorHtmlStructure(content) {
            // CKEditor bọc nội dung bằng các thẻ định dạng thật (p/span/strong...). Chỉ giữ các thẻ này để
            // giao diện vẫn render đúng; các thẻ mã HTML nằm trong nội dung (h1/style/script/doctype...) phải
            // chuyển thành text để học sinh nhìn thấy mã nguồn mà không thực thi được.
            const editorTags = /^(p|span|strong|b|em|i|u|s|br|wbr|a|img|figure|figcaption|ul|ol|li|blockquote|hr|table|thead|tbody|tfoot|tr|th|td|sub|sup|mark)$/i
            return String(content || '').replace(/<!--[\s\S]*?-->|<!DOCTYPE[^>]*>|<\/?[A-Za-z][^>]*>/gi, tag => {
                const tagNameMatch = tag.match(/^<\/?\s*([A-Za-z][\w:-]*)/)
                return tagNameMatch && editorTags.test(tagNameMatch[1])
                    ? tag
                    : tag.replace(/</g, '&lt;').replace(/>/g, '&gt;')
            })
        },

        preprocessMathML(content) {
            let result = content;

            for (let i = 0; i < 10; i++) {
                const before = result;

                result = result.replace(
                    /<mfenced([^>]+open="\{"[^>]*)>([\s\S]*?)<\/mfenced>/g,
                    (fullMatch, attributes, innerContent) => {
                        const hasClosingBrace = /close="\}"/.test(attributes);

                        if (hasClosingBrace) {
                            return `<mo>{</mo><mrow>${innerContent}</mrow><mo>}</mo>`;
                        } else {
                            return `<mo>{</mo><mrow>${innerContent}</mrow>`;
                        }
                    }
                );

                if (before === result) break;
            }

            return result;
        },

        setupMathJax() {
            const config = {
                tex: {
                    inlineMath: [['$', '$'], ['\\(', '\\)']],
                    displayMath: [['$$', '$$'], ['\\[', '\\]']]
                },
                loader: { load: ['[mml]/mml3'] },
                options: {
                    enableMenu: false,
                    enableExplorer: false,
                    enableAssistiveMml: false
                }
            }

            if (!window.MathJax) {
                window.MathJax = {
                    ...config,
                    startup: {
                        ready: () => {
                            window.MathJax.startup.defaultReady()
                            this.disableAllInteractions()
                        }
                    }
                }
                return Promise.resolve()
            }

            // MathJax runtime đã khởi tạo thì tuyệt đối không ghi đè lại API/cấu hình của nó.
            if (window.MathJax.typesetPromise) {
                const startupPromise = window.MathJax.startup && window.MathJax.startup.promise
                return startupPromise && typeof startupPromise.then === 'function'
                    ? startupPromise
                    : Promise.resolve()
            }

            // Script đã được khai báo nhưng chưa khởi tạo: chỉ bổ sung cấu hình ban đầu.
            window.MathJax = {
                ...window.MathJax,
                ...config,
                startup: {
                    ...(window.MathJax.startup || {}),
                    ready: () => {
                        window.MathJax.startup.defaultReady()
                        this.disableAllInteractions()
                    }
                }
            }
            return Promise.resolve()
        },

        typesetMath() {
            const container = this.$refs.contentContainer
            const mathJax = window.MathJax
            if (!container || !mathJax || !mathJax.typesetPromise) return

            const render = () => {
                if (mathJax.typesetClear) mathJax.typesetClear([container])
                mathJax.typesetPromise([container])
                    .then(() => {
                        this.forceDisableRenderedElements()
                        this.fixLinks()
                    })
                    .catch(err => console.error('MathJax render error:', err))
            }

            const startupPromise = mathJax.startup && mathJax.startup.promise
            if (startupPromise && typeof startupPromise.then === 'function') {
                startupPromise.then(render).catch(err => console.error('MathJax startup error:', err))
            } else {
                render()
            }
        },

        disableAllInteractions() {
            this.addDisableStyles()
        },

        preventMathJaxMenu(event) {
            const target = event.target
        },

        preventMathJaxClick(event) {
            const target = event.target
        },

        addDisableStyles() {
        },

        normalizeLatexDelimiters(content) {
            return String(content || '')
                .replace(/\$\$([\s\S]+?)\$\$/g, '\\[$1\\]')
                .replace(/(^|[^\\])\$([^$\n]+?)\$/g, (match, prefix, formula) => prefix + '\\(' + formula + '\\)')
        },

        loadWmfRenderer() {
            if (window.WMF) return Promise.resolve(window.WMF)
            if (window.__wmfRendererPromise) return window.__wmfRendererPromise

            window.__wmfRendererPromise = new Promise((resolve, reject) => {
                const script = document.createElement('script')
                script.src = 'https://cdn.jsdelivr.net/npm/wmf@1.0.2/dist/wmf.js'
                script.onload = () => {
                    if (window.WMF) resolve(window.WMF)
                    else reject(new Error('Không tìm thấy bộ chuyển WMF'))
                }
                script.onerror = () => reject(new Error('Không tải được bộ chuyển WMF'))
                document.head.appendChild(script)
            })

            return window.__wmfRendererPromise
        },

        convertWmfImages(content) {
            const html = String(content || '')
            if (!/data:image\/(?:x-)?wmf;base64,/i.test(html)) return Promise.resolve(html)

            return this.loadWmfRenderer().then((WMF) => {
                const parsed = new DOMParser().parseFromString(html, 'text/html')
                const imageNodes = Array.from(parsed.querySelectorAll('img'))

                imageNodes.forEach((imageNode) => {
                    const src = imageNode.getAttribute('src') || ''
                    const match = src.match(/^data:image\/(?:x-)?wmf;base64,([\s\S]+)$/i)
                    if (!match) return

                    try {
                        const binary = atob(match[1].replace(/\s/g, ''))
                        const bytes = new Uint8Array(binary.length)
                        for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i)
                        const size = WMF.image_size(bytes)
                        const width = Math.ceil(Number(size && size[0]))
                        const height = Math.ceil(Number(size && size[1]))
                        if (!Number.isFinite(width) || !Number.isFinite(height) || width < 1 || height < 1 || width > 4096 || height > 4096) return

                        const canvas = document.createElement('canvas')
                        canvas.width = width
                        canvas.height = height
                        WMF.draw_canvas(bytes, canvas)
                        imageNode.setAttribute('src', canvas.toDataURL('image/png'))
                    } catch (error) {
                        console.warn('[uc-latex-view] Không chuyển được ảnh WMF:', error)
                    }
                })

                return parsed.body.innerHTML
            }).catch((error) => {
                console.warn('[uc-latex-view] Không tải được bộ chuyển WMF:', error)
                return html
            })
        },

        renderContent(content) {
            const renderVersion = ++this.renderVersion
            // Luôn đưa dữ liệu về chuỗi trước khi preprocess/replace để cả ATC và
            // submission hiển thị được nội dung câu hỏi vừa cập nhật.
            content = this.normalizeRenderableContent(content)
            if (!content) {
                this.renderedContent = ''
                return
            }

            // Với môn Tin học, escape các thẻ mã nguồn như <style>/<script> trước khi sanitize để chúng hiện
            // nguyên văn mà không bị chạy hoặc bị bộ lọc xóa mất; wrapper do CKEditor sinh ra vẫn được giữ lại.
            if (this.escapeHtml) {
                content = this.literalHtmlTags
                    ? (this.preserveHtmlStructure
                        ? this.sanitizeLessonHtml(this.preserveEditorHtmlStructure(content))
                        : this.escapeAllHtmlTags(content))
                    : this.sanitizeLessonHtml(content);
            }

            // ✨ SAU ĐÓ mới preprocess MathML
            content = this.preprocessMathML(content)
            content = this.normalizeLatexDelimiters(content)

            // Convert newlines to <br> so plain-text content with \n renders correctly
            content = content.replace(/\n/g, '<br>')

            this.convertWmfImages(content).then((convertedContent) => {
                if (renderVersion !== this.renderVersion) return
                this.renderedContent = convertedContent

                this.$nextTick(() => {
                    this.fixLinks()
                    this.typesetMath()
                })
            })
        },

        fixLinks() {
            if (!this.$refs.contentContainer) return
            const inIframe = window !== window.top
            this.$refs.contentContainer.querySelectorAll('a[href]').forEach(a => {
                a.setAttribute('target', '_blank')
                a.setAttribute('rel', 'noopener noreferrer')
                if (inIframe) {
                    a.addEventListener('click', (e) => {
                        const href = a.getAttribute('href')
                        if (!href || href.startsWith('#')) return
                        e.preventDefault()
                        if (typeof window.top.openWindow === 'function') {
                            window.top.openWindow({ title: a.textContent?.trim() || href, url: href })
                        } else {
                            window.open(href, '_blank', 'noopener,noreferrer')
                        }
                    }, { passive: false })
                }
            })
        },

        forceDisableRenderedElements() {
        }
    },

    beforeUnmount() {
    }
	}
</script>

<style scoped>
.uc-latex-view figure.image {
    /* CKEditor có thể sinh figure dạng float; danh sách câu hỏi phải giữ ảnh như một block độc lập để không cắt đôi câu. */
    display: block;
    box-sizing: border-box;
    clear: both;
    float: none !important;
    max-width: 100%;
    margin: 0.9em auto;
    text-align: center;
}

.uc-latex-view figure.image img {
    display: block;
    height: auto;
    max-width: 100%;
    min-width: 0;
    margin: 0 auto;
}

.uc-latex-view figure.image.image_resized {
    width: auto;
    max-width: 100%;
}

.uc-latex-view figure.image.image_resized img {
    width: 100%;
}

.uc-latex-view p {
    margin: 0 0 0.5em;
    overflow-wrap: anywhere;
}

.uc-latex-view > :last-child {
    margin-bottom: 0;
}

.uc-latex-view img {
    max-width: 100%;
    height: auto;
}

.uc-latex-view table {
    max-width: 100%;
    border-collapse: collapse;
}

.uc-latex-view video,
.uc-latex-view iframe {
    display: block;
    max-width: 100%;
}

.uc-latex-view figcaption {
    display: block;
    text-align: center;
    font-size: 0.9em;
    color: rgba(0, 0, 0, 0.65);
}
</style>