async function initialize() {
  console.log('hello')
}
function secondsToMinuteSecond(totalSeconds) {
  if (!Number.isFinite(totalSeconds) || totalSeconds < 0) {
    return { minutes: 0, seconds: 0 };
  }
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  if (this?.$t) {
    return `${minutes} ${this.$t('message.MinutesUnit')} ${seconds} ${this.$t('message.SecondsUnit')}`;
  }
  const isEn = (localStorage.getItem('IsLanguage') && localStorage.getItem('IsLanguage') == 'true') || window.vueData?.v_Set?.locale?.locale === 'en';
  return isEn ? `${minutes}m ${seconds}s` : `${minutes} phút ${seconds} giây`;
}
vueData.initialize = initialize