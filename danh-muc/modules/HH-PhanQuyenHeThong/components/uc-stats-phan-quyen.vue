<template>
    <v-row class="stats-row">
        <v-col v-for="stat in statCards" :key="stat.key" cols="12" sm="6" xl="3">
            <v-card :elevation="0" class="stat-card">
                <v-card-text class="stat-card__body">
                    <div class="stat-card__content">
                        <div class="stat-card__label">{{ stat.label }}</div>
                        <div class="stat-card__value" :class="{ 'stat-card__value--text': stat.isTextValue }">
                            {{ stat.value }}
                        </div>
                        <div class="stat-card__helper">{{ stat.helper }}</div>
                    </div>
                    <v-avatar size="44" class="stat-card__icon">
                        <v-icon>{{ stat.icon }}</v-icon>
                    </v-avatar>
                </v-card-text>
            </v-card>
        </v-col>
    </v-row>
</template>

<script>
    export default {
    name: 'uc-stats-phan-quyen',
    props: {
        statCards: {
            type: Array,
            default: function () {
                return []
            }
        }
    }
}
</script>