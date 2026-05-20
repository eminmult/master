<template>
  <div class="hm-page hm-order-page">
    <div class="hm-page-inner">
      <nav v-if="order" class="hm-breadcrumb">
        <NuxtLink :to="localePath('/')">{{ $t('nav.home') }}</NuxtLink>
        <span class="hm-breadcrumb-sep">›</span>
        <NuxtLink :to="localePath(auth.isMaster ? '/master/orders' : '/client/orders')">{{ $t('nav.my_orders') }}</NuxtLink>
        <span class="hm-breadcrumb-sep">›</span>
        <span class="hm-breadcrumb-current">#{{ order.id }}</span>
      </nav>
      <div v-if="!loading && !order" class="hm-loading">404</div>
      <div v-else-if="order" class="order-layout">
        <!-- Order info -->
        <div class="order-info">
          <div class="card">
            <div class="oi-header">
              <span class="oi-id">#{{ order.id }}</span>
              <span class="badge" :class="statusClass(order.status)">{{ $t('status.' + order.status) }}</span>
            </div>
            <h1>{{ order.category?.name }}</h1>
            <p class="oi-desc">{{ order.description }}</p>

            <!-- Problem photos -->
            <div v-if="orderPhotos.length" class="oi-photos mt-3">
              <div class="oi-photos-label"><span class="icon icon-sm">photo_camera</span> {{ $t('orders.problem_photos') }}</div>
              <div class="oi-photos-grid">
                <button
                  v-for="(p, i) in orderPhotos"
                  :key="p.id"
                  type="button"
                  class="oi-photo-thumb"
                  @click="openLightbox(i)"
                >
                  <img :src="photoThumb(p.url)" :alt="'photo ' + (i + 1)" loading="lazy" />
                </button>
              </div>
            </div>

            <div class="oi-details mt-3">
              <div class="oi-row">
                <span class="icon icon-sm">location_on</span>
                <span>{{ order.full_address }}</span>
                <ClientOnly>
                  <button v-if="auth.isMaster" class="copy-btn" @click="copyAddress" :title="$t('orders.copy_address')">
                    <span class="icon icon-sm">content_copy</span>
                  </button>
                  <a v-if="auth.isMaster && order.lat && order.lng" :href="'https://www.google.com/maps/dir/?api=1&destination=' + order.lat + ',' + order.lng" target="_blank" class="maps-btn" :title="$t('orders.open_maps')">
                    <span class="icon icon-sm">map</span>
                  </a>
                </ClientOnly>
              </div>
              <div v-if="order.scheduled_at" class="oi-row"><span class="icon icon-sm">schedule</span> {{ formatDate(order.scheduled_at) }}</div>
              <div v-if="order.estimated_budget" class="oi-row"><span class="icon icon-sm">payments</span> ~{{ order.estimated_budget }} AZN</div>
            </div>

            <!-- Agreed info (visible to both after confirmation) -->
            <div v-if="order.agreed_date || order.agreed_price" class="agreed-box mt-3">
              <div class="agreed-title"><span class="icon icon-sm">handshake</span> {{ $t('orders.agreed_details') }}</div>
              <div v-if="order.agreed_date" class="agreed-row"><span class="icon icon-sm">event</span> {{ formatDate(order.agreed_date) }}</div>
              <div v-if="order.agreed_price" class="agreed-row"><span class="icon icon-sm">payments</span> {{ order.agreed_price }} AZN</div>
            </div>

            <!-- Partner info -->
            <div v-if="partner" class="oi-partner mt-3">
              <div class="oi-partner-header">
                <NuxtLink :to="localePath('/master/' + (partner.slug || partner.id))" class="oi-avatar" :style="partner.avatar_url ? { backgroundImage: 'url(' + partner.avatar_url + ')', color: 'transparent' } : {}">{{ partner.first_name[0] }}</NuxtLink>
                <div>
                  <NuxtLink :to="localePath('/master/' + (partner.slug || partner.id))" class="partner-name">{{ partner.first_name }} {{ partner.last_name }}</NuxtLink>
                  <div class="text-muted" style="font-size:0.813rem">
                    {{ auth.isClient ? $t('orders.master') : $t('orders.client') }}
                    <span v-if="partner.rating_avg"> · ★{{ partner.rating_avg }}</span>
                  </div>
                </div>
                <button v-if="isCallAvailable" type="button" class="call-btn" :title="$t('orders.call_in_app')" @click="startInAppCall">
                  <span class="icon">call</span>
                </button>
              </div>
              <button v-if="isCallAvailable" type="button" class="in-app-call-row" @click="startInAppCall">
                <span class="icon icon-sm">phone_in_talk</span>
                <span>{{ $t('orders.call_in_app') }}</span>
              </button>
            </div>

            <!-- === CLIENT STATUS INFO === -->
            <ClientOnly>
              <!-- searching_master: announcement open — show applicants with per-app chats -->
              <div v-if="auth.isClient && order.status === 'searching_master'" class="apps-box mt-3">
                <div class="apps-header">
                  <span class="icon">groups</span>
                  <div>
                    <strong>{{ $t('orders.applications_title', { n: activeApps.length }) }}</strong>
                    <p class="apps-sub">{{ $t('orders.applications_desc_v2') }}</p>
                  </div>
                </div>

                <div v-if="!applications.length" class="apps-empty">
                  <span class="icon">hourglass_top</span>
                  <p>{{ $t('orders.applications_empty') }}</p>
                </div>

                <div v-else>
                  <div class="apps-tabs">
                    <button
                      v-for="app in activeApps"
                      :key="app.id"
                      type="button"
                      class="apps-tab"
                      :class="{ active: activeAppId === app.id, 'has-proposal': app.status === 'proposed' }"
                      @click="selectApp(app.id)"
                    >
                      <span
                        class="apps-tab-avatar"
                        :style="app.master.avatar_url ? { backgroundImage: 'url(' + app.master.avatar_url + ')', color: 'transparent' } : {}"
                      >{{ app.master.first_name[0] }}</span>
                      <span class="apps-tab-name">{{ app.master.first_name }}</span>
                      <span v-if="app.status === 'proposed'" class="apps-tab-dot"></span>
                    </button>
                  </div>

                  <div v-if="activeApp" class="apps-panel">
                    <div class="apps-panel-head">
                      <NuxtLink
                        :to="localePath('/master/' + (activeApp.master.slug || activeApp.master.id))"
                        class="app-avatar"
                        :style="activeApp.master.avatar_url ? { backgroundImage: 'url(' + activeApp.master.avatar_url + ')', color: 'transparent' } : {}"
                      >{{ activeApp.master.first_name[0] }}</NuxtLink>
                      <div class="apps-panel-info">
                        <NuxtLink :to="localePath('/master/' + (activeApp.master.slug || activeApp.master.id))" class="app-name">
                          {{ activeApp.master.first_name }} {{ activeApp.master.last_name }}
                        </NuxtLink>
                        <div class="apps-panel-meta">
                          <span v-if="activeApp.master.rating_avg" class="app-rate">★ {{ activeApp.master.rating_avg }} · {{ activeApp.master.rating_count || 0 }}</span>
                          <span v-if="activeApp.master.master_profile?.completed_orders_count">
                            · {{ $t('orders.apps_completed', { n: activeApp.master.master_profile.completed_orders_count }) }}
                          </span>
                        </div>
                      </div>
                      <span class="app-status-tag" :class="'app-status-' + activeApp.status">
                        {{ $t('orders.app_status_' + activeApp.status) }}
                      </span>
                    </div>

                    <div v-if="activeApp.message" class="app-message">"{{ activeApp.message }}"</div>

                    <!-- Proposal box when master has sent an offer -->
                    <div v-if="activeApp.status === 'proposed'" class="proposal-box-inline">
                      <div class="proposal-header">
                        <span class="icon">description</span>
                        <strong>{{ $t('orders.proposal_title') }}</strong>
                      </div>
                      <div class="proposal-details">
                        <div class="proposal-row"><span class="icon icon-sm">event</span> {{ formatDate(activeApp.proposed_date) }}</div>
                        <div class="proposal-row"><span class="icon icon-sm">payments</span> {{ activeApp.proposed_price }} AZN</div>
                      </div>
                      <div class="proposal-actions">
                        <button class="btn btn-primary" :disabled="appActionId === activeApp.id" @click="acceptProposal(activeApp.id)">
                          <span class="icon icon-sm">check</span> {{ $t('orders.apps_accept_proposal') }}
                        </button>
                        <button class="btn btn-outline" :disabled="appActionId === activeApp.id" @click="rejectProposal(activeApp.id)">
                          <span class="icon icon-sm">chat</span> {{ $t('orders.client_discuss_more') }}
                        </button>
                      </div>
                    </div>

                    <!-- Chat panel -->
                    <div class="app-chat" :class="{ 'app-chat-locked': !canChat(activeApp) }">
                      <div v-if="!canChat(activeApp)" class="app-chat-locked-note">
                        {{ $t('orders.apps_chat_locked') }}
                      </div>
                      <div v-else ref="chatScrollEl" class="app-chat-messages">
                        <div v-if="!appMessages.length" class="app-chat-hint">
                          {{ $t('orders.apps_chat_hint') }}
                        </div>
                        <div
                          v-for="m in appMessages"
                          :key="m.id"
                          class="app-chat-msg"
                          :class="{ mine: m.sender_id === auth.user?.id }"
                        >
                          <ChatProposalBubble v-if="isProposalMessage(m.text)" :payload="parseProposal(m.text)" />
                          <div v-else class="app-chat-bubble">{{ m.text }}</div>
                          <div class="app-chat-time">{{ formatTime(m.created_at) }}</div>
                        </div>
                      </div>
                      <form v-if="canChat(activeApp)" class="app-chat-input" @submit.prevent="sendAppMessage">
                        <input
                          v-model="chatDraft"
                          type="text"
                          :placeholder="$t('orders.apps_chat_placeholder')"
                          maxlength="2000"
                        />
                        <button type="submit" class="btn btn-primary btn-sm" :disabled="!chatDraft.trim() || sendingChat">
                          <span class="icon icon-sm">send</span>
                        </button>
                      </form>
                    </div>

                    <div v-if="['pending', 'discussing', 'proposed'].includes(activeApp.status)" class="apps-panel-foot">
                      <button class="btn btn-outline btn-sm reject-master-btn" :disabled="appActionId === activeApp.id" @click="rejectApplication(activeApp.id)">
                        <span class="icon icon-sm">close</span> {{ $t('orders.apps_reject') }}
                      </button>
                    </div>
                  </div>

                  <!-- Rejected/withdrawn applications — collapsed list -->
                  <details v-if="inactiveApps.length" class="apps-inactive">
                    <summary>{{ $t('orders.apps_inactive', { n: inactiveApps.length }) }}</summary>
                    <ul>
                      <li v-for="app in inactiveApps" :key="app.id">
                        {{ app.master.first_name }} {{ app.master.last_name }} —
                        <span :class="'app-status-' + app.status">{{ $t('orders.app_status_' + app.status) }}</span>
                      </li>
                    </ul>
                  </details>
                </div>
              </div>

              <div v-if="auth.isClient && order.status === 'pending_master'" class="status-banner pending mt-3">
                <div class="sb-icon"><span class="icon">hourglass_top</span></div>
                <div>
                  <strong>{{ $t('orders.waiting_master_title') }}</strong>
                  <p>{{ $t('orders.waiting_master_desc') }}</p>
                </div>
              </div>
              <div v-if="auth.isClient && order.status === 'discussion'" class="status-banner discussion mt-3">
                <div class="sb-icon"><span class="icon">chat</span></div>
                <div>
                  <strong>{{ $t('orders.discussion_title') }}</strong>
                  <p>{{ $t('orders.discussion_desc') }}</p>
                </div>
              </div>
              <!-- pending_client: Master proposed arrival time, client must pay callout fee to confirm -->
              <div v-if="auth.isClient && (order.status === 'pending_client' || order.status === 'pending_payment')" class="proposal-box mt-3">
                <div class="proposal-header">
                  <span class="icon">description</span>
                  <strong>{{ $t('orders.proposal_title') }}</strong>
                </div>
                <div class="proposal-details">
                  <div v-if="order.agreed_date" class="proposal-row"><span class="icon icon-sm">event</span> {{ formatDate(order.agreed_date) }}</div>
                  <div class="proposal-row proposal-callout">
                    <span class="icon icon-sm">payments</span>
                    {{ $t('orders.callout_fee_label', { amount: '25' }) }}
                  </div>
                </div>
                <div class="proposal-actions">
                  <button class="btn btn-primary" @click="clientConfirm">
                    <span class="icon icon-sm">payments</span> {{ $t('orders.client_pay_and_confirm', { amount: '25' }) }}
                  </button>
                  <button class="btn btn-outline" @click="clientReject">
                    <span class="icon icon-sm">chat</span> {{ $t('orders.client_discuss_more') }}
                  </button>
                </div>
              </div>

              <div v-if="auth.isClient && order.status === 'confirmed'" class="status-banner confirmed mt-3">
                <div class="sb-icon"><span class="icon">event_available</span></div>
                <div>
                  <strong>{{ $t('orders.confirmed_title') }}</strong>
                  <p>{{ $t('orders.confirmed_desc') }}</p>
                </div>
              </div>
              <div v-if="auth.isClient && order.status === 'on_the_way'" class="status-banner active mt-3">
                <div class="sb-icon"><span class="icon">directions_car</span></div>
                <div>
                  <strong>{{ $t('orders.on_the_way_title') }}</strong>
                  <p>{{ $t('orders.on_the_way_desc') }}</p>
                </div>
              </div>
              <div v-if="auth.isClient && order.status === 'arrived'" class="status-banner active mt-3">
                <div class="sb-icon"><span class="icon">flag</span></div>
                <div>
                  <strong>{{ $t('orders.arrived_title') }}</strong>
                  <p>{{ $t('orders.arrived_desc') }}</p>
                </div>
              </div>
              <div v-if="auth.isClient && order.status === 'in_progress'" class="status-banner active mt-3">
                <div class="sb-icon"><span class="icon">construction</span></div>
                <div>
                  <strong>{{ $t('orders.in_progress_title') }}</strong>
                  <p>{{ $t('orders.in_progress_desc') }}</p>
                </div>
              </div>
              <!-- awaiting_completion: client confirms -->
              <div v-if="auth.isClient && order.status === 'awaiting_completion'" class="status-banner confirmed mt-3">
                <div class="sb-icon"><span class="icon">task_alt</span></div>
                <div style="flex:1">
                  <strong>{{ $t('orders.master_finished') }}</strong>
                  <p>{{ $t('orders.confirm_completion_desc') }}</p>
                  <button class="btn btn-primary mt-2" @click="updateStatus('completed')">
                    <span class="icon icon-sm">check_circle</span> {{ $t('orders.confirm_completion') }}
                  </button>
                </div>
              </div>
              <!-- awaiting_completion: master waits -->
              <div v-if="auth.isMaster && order.status === 'awaiting_completion'" class="status-banner pending mt-3">
                <div class="sb-icon"><span class="icon">hourglass_top</span></div>
                <div>
                  <strong>{{ $t('orders.waiting_client_title') }}</strong>
                  <p>{{ $t('orders.confirm_completion_desc') }}</p>
                </div>
              </div>
            </ClientOnly>

            <!-- === MASTER ACTIONS === -->
            <ClientOnly><div v-if="auth.isMaster" class="oi-actions mt-3">

              <!-- pending_master: Discuss / Decline + 24h warning -->
              <template v-if="order.status === 'pending_master'">
                <div class="status-banner pending-master-warn">
                  <div class="sb-icon"><span class="icon">timer</span></div>
                  <div>
                    <strong>{{ $t('orders.pending_master_24h_title') }}</strong>
                    <p>{{ $t('orders.pending_master_24h_desc') }}</p>
                  </div>
                </div>
                <button class="btn btn-primary btn-block" @click="acceptOrder">
                  <span class="icon icon-sm">chat</span> {{ $t('orders.discuss') }}
                </button>
                <button class="btn btn-outline btn-block" style="color:var(--danger);border-color:var(--danger)" @click="showCancelPopup = true">
                  <span class="icon icon-sm">close</span> {{ $t('orders.decline') }}
                </button>
              </template>

              <!-- pending_client: waiting for client -->
              <template v-if="order.status === 'pending_client'">
                <div class="status-banner pending">
                  <div class="sb-icon"><span class="icon">hourglass_top</span></div>
                  <div>
                    <strong>{{ $t('orders.waiting_client_title') }}</strong>
                    <p>{{ $t('orders.waiting_client_desc') }}</p>
                  </div>
                </div>
              </template>

              <!-- discussion: Accept work (opens popup) -->
              <template v-if="order.status === 'discussion'">
                <button class="btn btn-primary btn-block" @click="showConfirmPopup = true">
                  <span class="icon icon-sm">handshake</span> {{ $t('orders.confirm_work') }}
                </button>
              </template>

              <!-- confirmed/accepted: Start journey -->
              <template v-if="['confirmed', 'accepted'].includes(order.status)">
                <button class="btn btn-primary btn-block" @click="updateStatus('on_the_way')">
                  <span class="icon icon-sm">directions_car</span> {{ $t('orders.departed') }}
                </button>
              </template>

              <!-- on_the_way -->
              <button v-if="order.status === 'on_the_way'" class="btn btn-primary btn-block" @click="updateStatus('arrived')">
                <span class="icon icon-sm">flag</span> {{ $t('orders.arrived') }}
              </button>

              <!-- arrived → start work with duration -->
              <button v-if="order.status === 'arrived'" class="btn btn-primary btn-block" @click="showDurationPopup = true">
                <span class="icon icon-sm">construction</span> {{ $t('orders.started') }}
              </button>

              <!-- in_progress -->
              <button v-if="order.status === 'in_progress'" class="btn btn-success btn-block" @click="updateStatus('completed')">
                <span class="icon icon-sm">check_circle</span> {{ $t('orders.finished') }}
              </button>
            </div></ClientOnly>

            <!-- === CANCEL (both sides, any active status) === -->
            <ClientOnly><div v-if="canCancel" class="mt-3">
              <button class="btn btn-outline btn-block btn-sm btn-cancel" @click="showCancelPopup = true">
                <span class="icon icon-sm">cancel</span> {{ $t('orders.cancel_order') }}
              </button>
            </div></ClientOnly>

            <!-- Timeline -->
            <OrderTimeline v-if="order.status_history?.length" :history="order.status_history" class="mt-3" />

            <!-- Review form (inline for non-forced) -->
            <ClientOnly>
              <ReviewForm
                v-if="showReviewForm && !forceReviewPopup"
                :order-id="order.id"
                :reviewee-name="partner ? `${partner.first_name} ${partner.last_name}` : ''"
                @reviewed="onReviewed"
              />
            </ClientOnly>

            <!-- Report button (after completion) -->
            <ClientOnly>
              <button
                v-if="['completed', 'closed', 'awaiting_completion'].includes(order.status)"
                class="btn btn-sm mt-3"
                style="color:var(--hm-text-3);font-size:0.75rem"
                @click="showDisputePopup = true"
              >
                <span class="icon icon-sm">flag</span> {{ $t('orders.report') }}
              </button>
              <!-- Repeat order (client, closed) -->
              <NuxtLink
                v-if="auth.isClient && ['completed', 'closed'].includes(order.status) && order.master_id"
                :to="localePath('/client/new-order?master_id=' + order.master_id + '&master_name=' + encodeURIComponent((order.master?.first_name || '') + ' ' + (order.master?.last_name || '')))"
                class="btn btn-outline btn-sm mt-1"
              >
                <span class="icon icon-sm">replay</span> {{ $t('orders.repeat_order') }}
              </NuxtLink>
            </ClientOnly>
          </div>
        </div>

        <!-- Map + Chat column -->
        <div class="order-right">
          <!-- Live Map (visible during on_the_way, arrived) -->
            <OrderMap
              v-if="showMap"
              :order-id="order.id"
              :order-lat="parseFloat(order.lat) || 40.4093"
              :order-lng="parseFloat(order.lng) || 49.8671"
              :master-lat="order.master?.master_profile?.current_lat ? parseFloat(order.master.master_profile.current_lat) : null"
              :master-lng="order.master?.master_profile?.current_lng ? parseFloat(order.master.master_profile.current_lng) : null"
              :is-master="auth.isMaster"
              :is-tracking="['on_the_way', 'arrived'].includes(order.status)"
            />

          <!-- Chat -->
          <OrderChat
            :order-id="order.id"
            :partner-name="partner ? `${partner.first_name} ${partner.last_name}` : ''"
            :chat-active="isChatActive"
            :partner-online="partnerIsOnline"
          />
        </div>
      </div>

      <!-- Confirm popup -->
      <Teleport to="body">
        <div v-if="showConfirmPopup" class="popup-overlay" @click.self="showConfirmPopup = false">
          <div class="popup-card">
            <div class="popup-header">
              <h3><span class="icon">handshake</span> {{ $t('orders.confirm_work') }}</h3>
              <button @click="showConfirmPopup = false"><span class="icon">close</span></button>
            </div>
            <div class="popup-body">
              <!-- Date picker -->
              <div class="form-group">
                <label>{{ $t('orders.agreed_date') }} *</label>
                <DatePicker v-model="pickerDate" />
              </div>
              <!-- Time picker -->
              <div class="form-group">
                <label>{{ $t('orders.agreed_time') }} *</label>
                <div class="time-picker">
                  <select v-model="pickerHour" class="time-select">
                    <option v-for="h in hours" :key="h" :value="h">{{ h.toString().padStart(2, '0') }}</option>
                  </select>
                  <span class="time-sep">:</span>
                  <select v-model="pickerMinute" class="time-select">
                    <option v-for="m in minutes" :key="m" :value="m">{{ m.toString().padStart(2, '0') }}</option>
                  </select>
                </div>
              </div>
              <!-- Selected datetime preview -->
              <div v-if="pickerDate && pickerHour !== null" class="datetime-preview">
                <span class="icon icon-sm">event</span>
                {{ formatPickerDate() }}
              </div>
              <!-- Цена работ обсуждается в чате. Платформа фиксирует только время прибытия + плату за вызов. -->
              <p class="text-muted price-hint">{{ $t('orders.price_via_chat_hint') }}</p>
            </div>
            <div class="popup-footer">
              <button class="btn btn-primary btn-block" @click="confirmOrder" :disabled="!pickerDate || pickerHour === null || confirming">
                {{ confirming ? $t('common.loading') : $t('orders.confirm_work') }}
              </button>
            </div>
          </div>
        </div>
      </Teleport>

      <!-- Callout fee payment modal -->
      <CalloutFeePayModal v-model="showPayCallout" :order-id="Number(route.params.id)" @paid="(o) => order = o" />

      <!-- Cancel popup -->
      <Teleport to="body">
        <div v-if="showCancelPopup" class="popup-overlay" @click.self="showCancelPopup = false">
          <div class="popup-card">
            <div class="popup-header popup-header-danger">
              <h3><span class="icon">cancel</span> {{ $t('orders.cancel_order') }}</h3>
              <button @click="showCancelPopup = false"><span class="icon">close</span></button>
            </div>
            <div class="popup-body">
              <p class="cancel-warn">{{ $t('orders.cancel_confirm_text') }}</p>
              <div class="form-group mt-2">
                <label>{{ $t('orders.cancel_reason') }}</label>
                <textarea v-model="cancelReason" rows="3" :placeholder="$t('orders.cancel_reason_placeholder')"></textarea>
              </div>
            </div>
            <div class="popup-footer cancel-footer">
              <button class="btn btn-outline btn-block" @click="showCancelPopup = false">
                {{ $t('orders.cancel_back') }}
              </button>
              <button class="btn btn-danger btn-block" @click="confirmCancel" :disabled="canceling">
                <span class="icon icon-sm">cancel</span>
                {{ canceling ? $t('common.loading') : $t('orders.cancel_confirm') }}
              </button>
            </div>
          </div>
        </div>
      </Teleport>

      <!-- Duration popup -->
      <Teleport to="body">
        <div v-if="showDurationPopup" class="popup-overlay" @click.self="showDurationPopup = false">
          <div class="popup-card">
            <div class="popup-header">
              <h3><span class="icon">timer</span> {{ $t('orders.work_duration') }}</h3>
              <button @click="showDurationPopup = false"><span class="icon">close</span></button>
            </div>
            <div class="popup-body">
              <p class="text-muted" style="font-size:0.875rem">{{ $t('orders.duration_desc') }}</p>
              <div class="duration-grid mt-2">
                <button
                  v-for="d in durationOptions"
                  :key="d.value"
                  class="duration-btn"
                  :class="{ active: selectedDuration === d.value }"
                  @click="selectedDuration = d.value"
                >
                  <span class="dur-time">{{ d.label }}</span>
                  <span class="dur-end text-muted">{{ calcEndTime(d.value) }}</span>
                </button>
              </div>
              <div v-if="selectedDuration" class="duration-preview mt-2">
                <span class="icon icon-sm">schedule</span>
                {{ $t('orders.estimated_end') }}: <strong>{{ calcEndTime(selectedDuration) }}</strong>
              </div>
            </div>
            <div class="popup-footer">
              <button class="btn btn-primary btn-block" @click="startWork" :disabled="!selectedDuration || startingWork">
                {{ startingWork ? $t('common.loading') : $t('orders.started') }}
              </button>
            </div>
          </div>
        </div>
      </Teleport>

      <!-- Forced review popup -->
      <Teleport to="body">
        <div v-if="forceReviewPopup" class="popup-overlay">
          <div class="popup-card" style="max-width:480px">
            <div class="popup-header">
              <h3><span class="icon">star</span> {{ $t('review.leave_review') }}</h3>
            </div>
            <div class="popup-body">
              <ReviewForm
                :order-id="order.id"
                :reviewee-name="partner ? `${partner.first_name} ${partner.last_name}` : ''"
                :inline="true"
                @reviewed="onReviewed"
              />
            </div>
          </div>
        </div>
      </Teleport>

      <!-- Photo lightbox -->
      <Teleport to="body">
        <div v-if="lightboxIndex !== null" class="lightbox-overlay" @click.self="lightboxIndex = null">
          <button class="lightbox-close" @click="lightboxIndex = null"><span class="icon">close</span></button>
          <button v-if="orderPhotos.length > 1" class="lightbox-nav lightbox-prev" @click.stop="lightboxPrev"><span class="icon">chevron_left</span></button>
          <img :src="photoFull(orderPhotos[lightboxIndex].url)" class="lightbox-img" @click.stop />
          <button v-if="orderPhotos.length > 1" class="lightbox-nav lightbox-next" @click.stop="lightboxNext"><span class="icon">chevron_right</span></button>
          <div v-if="orderPhotos.length > 1" class="lightbox-counter">{{ lightboxIndex + 1 }} / {{ orderPhotos.length }}</div>
        </div>
      </Teleport>

      <!-- Dispute popup -->
      <Teleport to="body">
        <div v-if="showDisputePopup" class="popup-overlay" @click.self="showDisputePopup = false">
          <div class="popup-card">
            <div class="popup-header popup-header-danger">
              <h3><span class="icon">flag</span> {{ $t('orders.report') }}</h3>
              <button @click="showDisputePopup = false"><span class="icon">close</span></button>
            </div>
            <div class="popup-body">
              <div class="form-group">
                <label>{{ $t('orders.report_reason') }}</label>
                <select v-model="disputeReason">
                  <option value="">{{ $t('common.select') }}</option>
                  <option value="no_show">{{ $t('orders.report_no_show') }}</option>
                  <option value="bad_quality">{{ $t('orders.report_bad_quality') }}</option>
                  <option value="rude_behavior">{{ $t('orders.report_rude') }}</option>
                  <option value="price_issue">{{ $t('orders.report_price') }}</option>
                  <option value="other">{{ $t('orders.report_other') }}</option>
                </select>
              </div>
              <div class="form-group">
                <label>{{ $t('orders.report_details') }}</label>
                <textarea v-model="disputeDesc" rows="3"></textarea>
              </div>
            </div>
            <div class="popup-footer">
              <button class="btn btn-danger btn-block" @click="submitDispute" :disabled="!disputeReason || disputeSubmitting">
                {{ disputeSubmitting ? $t('common.loading') : $t('orders.report_submit') }}
              </button>
            </div>
          </div>
        </div>
      </Teleport>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'hm', middleware: 'auth' })

const { t: $t, locale } = useI18n()
const { apiFetch } = useApi()
const toast = useToast()
const auth = useAuthStore()
const route = useRoute()
const localePath = useLocalePath()

const { data: order, pending: loading } = await useAsyncData(
  `order-${route.params.id}`,
  async () => {
    try {
      const res = await apiFetch<{ order: any }>(`/orders/${route.params.id}`)
      return res.order
    } catch { return null }
  },
  { default: () => null },
)
const showConfirmPopup = ref(false)
const showCancelPopup = ref(false)
const showDisputePopup = ref(false)
const disputeReason = ref('')
const disputeDesc = ref('')
const disputeSubmitting = ref(false)

async function submitDispute() {
  if (!disputeReason.value) return
  disputeSubmitting.value = true
  try {
    await apiFetch(`/orders/${route.params.id}/dispute`, {
      method: 'POST',
      body: { reason: disputeReason.value, description: disputeDesc.value || undefined },
    })
    showDisputePopup.value = false
    toast.success($t('orders.report_sent'))
  } catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
  disputeSubmitting.value = false
}
const showDurationPopup = ref(false)
const selectedDuration = ref<number | null>(null)
const startingWork = ref(false)

const durationOptions = computed(() => {
  const m = $t('orders.min_short')
  const h = $t('orders.hour_short')
  return [
    { value: 30, label: `30 ${m}` },
    { value: 60, label: `1 ${h}` },
    { value: 90, label: `1.5 ${h}` },
    { value: 120, label: `2 ${h}` },
    { value: 180, label: `3 ${h}` },
    { value: 240, label: `4 ${h}` },
    { value: 360, label: `6 ${h}` },
    { value: 480, label: `8 ${h}` },
  ]
})

function calcEndTime(minutes: number): string {
  return fmtTime(new Date(Date.now() + minutes * 60000))
}

async function startWork() {
  if (!selectedDuration.value) return
  startingWork.value = true
  try {
    const res = await apiFetch<{ order: any }>(`/orders/${route.params.id}/status`, {
      method: 'POST',
      body: { status: 'in_progress', estimated_duration: selectedDuration.value },
    })
    order.value = res.order

    // Send duration info to chat
    const endTime = calcEndTime(selectedDuration.value)
    await apiFetch(`/orders/${route.params.id}/messages`, {
      method: 'POST',
      body: { text: JSON.stringify({ _type: 'work_started', duration: selectedDuration.value, end_time: endTime }) },
    })

    showDurationPopup.value = false
  } catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
  startingWork.value = false
}
const cancelReason = ref('')
const canceling = ref(false)
const agreedPrice = ref<number | null>(null)
const confirming = ref(false)

// Date/time picker
const pickerDate = ref('')
const pickerHour = ref<number | null>(null)
const pickerMinute = ref(0)
const todayStr = computed(() => new Date().toISOString().split('T')[0])
const hours = Array.from({ length: 15 }, (_, i) => i + 7) // 07:00 - 21:00
const minutes = [0, 15, 30, 45]

const agreedDate = computed(() => {
  if (!pickerDate.value || pickerHour.value === null) return ''
  const h = String(pickerHour.value).padStart(2, '0')
  const m = String(pickerMinute.value).padStart(2, '0')
  return `${pickerDate.value}T${h}:${m}`
})

function formatDateShort(dateStr: string): string {
  const d = new Date(dateStr)
  const day = d.getDate().toString().padStart(2, '0')
  const month = (d.getMonth() + 1).toString().padStart(2, '0')
  const weekday = $t('days.' + d.getDay())
  return `${day}.${month}.${d.getFullYear()}, ${weekday}`
}

function formatPickerDate(): string {
  if (!pickerDate.value || pickerHour.value === null) return ''
  const d = new Date(pickerDate.value)
  const day = d.getDate().toString().padStart(2, '0')
  const month = (d.getMonth() + 1).toString().padStart(2, '0')
  const year = d.getFullYear()
  const h = String(pickerHour.value).padStart(2, '0')
  const m = String(pickerMinute.value).padStart(2, '0')
  return `${day}.${month}.${year} ${h}:${m}`
}

const partner = computed(() => {
  if (!order.value) return null
  return (auth.isClient || auth.isAdmin) ? order.value.master : order.value.client
})

const orderPhotos = computed<any[]>(() => Array.isArray(order.value?.photos) ? order.value.photos : [])

function photoThumb(url: string): string {
  return url.replace(/_large\.webp$/, '_thumb.webp').replace(/_medium\.webp$/, '_thumb.webp')
}
function photoFull(url: string): string {
  return url.replace(/_thumb\.webp$/, '_large.webp').replace(/_medium\.webp$/, '_large.webp')
}

const lightboxIndex = ref<number | null>(null)
function openLightbox(i: number) { lightboxIndex.value = i }
function lightboxPrev() {
  if (lightboxIndex.value === null) return
  lightboxIndex.value = (lightboxIndex.value - 1 + orderPhotos.value.length) % orderPhotos.value.length
}
function lightboxNext() {
  if (lightboxIndex.value === null) return
  lightboxIndex.value = (lightboxIndex.value + 1) % orderPhotos.value.length
}

const partnerIsOnline = computed(() => {
  if (!order.value) return false
  const master = order.value.master
  return master?.master_profile?.status === 'online'
})

const chatStatuses = ['discussion', 'pending_client', 'confirmed', 'accepted', 'on_the_way', 'arrived', 'in_progress']
const isChatActive = computed(() => chatStatuses.includes(order.value?.status))
// In-app voice calls — enabled only after the work is confirmed by both sides.
// Phone numbers are NEVER shown to either party.
const callAvailableStatuses = ['confirmed', 'accepted', 'on_the_way', 'arrived', 'in_progress', 'awaiting_completion']
const isCallAvailable = computed(() => callAvailableStatuses.includes(order.value?.status))
async function startInAppCall() {
  if (!order.value || !partner.value) return
  const calls = useCallsStore()
  const peerName = `${partner.value.first_name || ''} ${partner.value.last_name || ''}`.trim()
  await calls.startOutgoing({
    orderId: order.value.id,
    calleeId: partner.value.id,
    calleeName: peerName,
    calleeAvatar: partner.value.avatar_url || null,
  })
}
const showMap = computed(() => ['on_the_way', 'arrived', 'in_progress', 'confirmed'].includes(order.value?.status))

const forceReviewPopup = computed(() => {
  if (!order.value) return false
  if (order.value.status !== 'completed') return false
  if (auth.isClient && !order.value.client_reviewed) return true
  if (auth.isMaster && !order.value.master_reviewed) return true
  return false
})

function onReviewed() {
  // Refresh order to update reviewed flags
  apiFetch<{ order: any }>(`/orders/${route.params.id}`).then(res => { order.value = res.order }).catch(() => {})
}

const showReviewForm = computed(() => {
  if (!order.value) return false
  if (!['completed', 'awaiting_review'].includes(order.value.status)) return false
  if (auth.isClient && order.value.client_reviewed) return false
  if (auth.isMaster && order.value.master_reviewed) return false
  return true
})

const canCancel = computed(() => {
  if (!order.value) return false
  const s = order.value.status
  if (s.startsWith('canceled') || s === 'completed' || s === 'closed') return false
  // Master has "Decline" button on pending_master — don't show duplicate cancel
  if (s === 'pending_master' && auth.isMaster) return false
  return auth.user?.id === order.value.client_id || auth.user?.id === order.value.master_id
})

const { statusClass } = useStatusClass()

const { formatDateTime: formatDate, formatTime: fmtTime } = useFormatDate()

function copyAddress() {
  if (order.value?.full_address) {
    navigator.clipboard?.writeText(order.value.full_address)
  }
}

// Applications (client side, order.status === 'searching_master')
const applications = computed<any[]>(() => order.value?.applications || [])
const ACTIVE_APP_STATUSES = ['pending', 'discussing', 'proposed']
const activeApps = computed(() => applications.value.filter((a: any) => ACTIVE_APP_STATUSES.includes(a.status)))
const inactiveApps = computed(() => applications.value.filter((a: any) => !ACTIVE_APP_STATUSES.includes(a.status)))
const activeAppId = ref<number | null>(null)
const activeApp = computed(() => applications.value.find((a: any) => a.id === activeAppId.value) || null)
const appActionId = ref<number | null>(null)
const appMessages = ref<any[]>([])
const chatDraft = ref('')
const sendingChat = ref(false)
const chatScrollEl = ref<HTMLElement | null>(null)
let appChatPoll: ReturnType<typeof setInterval> | null = null

function canChat(app: any): boolean {
  return app && ['pending', 'discussing', 'proposed'].includes(app.status)
}

function isProposalMessage(text: string): boolean {
  if (!text) return false
  try { return JSON.parse(text)._type === 'proposal' } catch { return false }
}
function parseProposal(text: string): any {
  try { return JSON.parse(text) } catch { return {} }
}

watch(activeApps, (v) => {
  if (!activeAppId.value && v.length) activeAppId.value = v[0].id
  // If previously active app got rejected, swap to first active
  if (activeAppId.value && !v.find((a: any) => a.id === activeAppId.value)) {
    activeAppId.value = v[0]?.id || null
  }
}, { immediate: true })

watch(activeAppId, () => {
  loadAppMessages()
}, { immediate: true })

async function loadAppMessages() {
  if (!activeAppId.value || !canChat(activeApp.value)) { appMessages.value = []; return }
  try {
    // Incremental fetch — `since=<last_id>` on already-loaded threads so the
    // 1Hz poll returns ~200 bytes when there's nothing new.
    const lastId = appMessages.value.reduce((m: number, x: any) => Math.max(m, x.id || 0), 0)
    const url = lastId > 0
      ? `/order-applications/${activeAppId.value}/messages?since=${lastId}`
      : `/order-applications/${activeAppId.value}/messages`
    const res = await apiFetch<{ messages: any[] }>(url)
    if (lastId > 0) {
      if (!res.messages?.length) return
      const seen = new Set(appMessages.value.map((m: any) => m.id))
      const fresh = res.messages.filter((m: any) => !seen.has(m.id))
      if (fresh.length) {
        appMessages.value = [...appMessages.value, ...fresh]
        await nextTick()
        if (chatScrollEl.value) chatScrollEl.value.scrollTop = chatScrollEl.value.scrollHeight
      }
    } else {
      appMessages.value = res.messages || []
      await nextTick()
      if (chatScrollEl.value) chatScrollEl.value.scrollTop = chatScrollEl.value.scrollHeight
    }
  } catch {}
}

function selectApp(id: number) { activeAppId.value = id }

async function sendAppMessage() {
  if (!activeAppId.value || !chatDraft.value.trim()) return
  sendingChat.value = true
  try {
    const res = await apiFetch<{ message: any }>(`/order-applications/${activeAppId.value}/messages`, {
      method: 'POST',
      body: { text: chatDraft.value.trim() },
    })
    appMessages.value = [...appMessages.value, res.message]
    chatDraft.value = ''
    await nextTick()
    if (chatScrollEl.value) chatScrollEl.value.scrollTop = chatScrollEl.value.scrollHeight
    // If this was the first client message, app may have transitioned to discussing → refresh order
    await refreshOrder()
  } catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
  finally { sendingChat.value = false }
}

async function acceptProposal(appId: number) {
  if (!confirm($t('orders.apps_accept_proposal_confirm'))) return
  appActionId.value = appId
  try {
    await apiFetch(`/order-applications/${appId}/accept-proposal`, { method: 'POST' })
    toast.success($t('orders.apps_proposal_accepted_toast'))
    await refreshOrder()
  } catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
  appActionId.value = null
}

async function rejectProposal(appId: number) {
  appActionId.value = appId
  try {
    await apiFetch(`/order-applications/${appId}/reject-proposal`, { method: 'POST' })
    await refreshOrder()
    loadAppMessages()
  } catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
  appActionId.value = null
}

async function rejectApplication(appId: number) {
  if (!confirm($t('orders.apps_reject_confirm'))) return
  appActionId.value = appId
  try {
    await apiFetch(`/order-applications/${appId}/reject`, { method: 'POST' })
    await refreshOrder()
  } catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
  appActionId.value = null
}

async function refreshOrder() {
  try {
    const res = await apiFetch<{ order: any }>(`/orders/${route.params.id}`)
    order.value = res.order
  } catch {}
}

async function acceptOrder() {
  try { const res = await apiFetch<{ order: any }>(`/orders/${route.params.id}/accept`, { method: 'POST' }); order.value = res.order }
  catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
}

async function declineOrder() {
  try { await apiFetch(`/orders/${route.params.id}/decline`, { method: 'POST' }); order.value = { ...order.value, status: 'canceled_by_master' } }
  catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
}

async function confirmOrder() {
  if (!agreedDate.value) return
  confirming.value = true
  try {
    const res = await apiFetch<{ order: any }>(`/orders/${route.params.id}/confirm`, {
      method: 'POST',
      body: { agreed_date: agreedDate.value },
    })
    order.value = res.order
    showConfirmPopup.value = false
  } catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
  confirming.value = false
}

// Client "confirms" via the callout-fee payment modal — there is no
// payment-less confirm path anymore. Opening the modal is the new clientConfirm.
const showPayCallout = ref(false)
async function clientConfirm() {
  showPayCallout.value = true
}

async function clientReject() {
  try {
    const res = await apiFetch<{ order: any }>(`/orders/${route.params.id}/reject-proposal`, { method: 'POST' })
    order.value = res.order
  } catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
}

async function updateStatus(status: string) {
  try { const res = await apiFetch<{ order: any }>(`/orders/${route.params.id}/status`, { method: 'POST', body: { status } }); order.value = res.order }
  catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
}

async function confirmCancel() {
  canceling.value = true
  try {
    // If master declining pending request — use decline endpoint
    if (order.value?.status === 'pending_master' && auth.isMaster) {
      await apiFetch(`/orders/${route.params.id}/decline`, { method: 'POST' })
      order.value = { ...order.value, status: 'canceled_by_master' }
    } else {
      await apiFetch(`/orders/${route.params.id}/cancel`, { method: 'POST', body: { reason: cancelReason.value || undefined } })
      order.value = { ...order.value, status: auth.isClient ? 'canceled_by_client' : 'canceled_by_master' }
    }
    showCancelPopup.value = false
    cancelReason.value = ''
  } catch (e: any) { toast.error(e?.data?.message || $t('auth.error_occurred')) }
  canceling.value = false
}

let orderPollTimer: ReturnType<typeof setInterval> | null = null

async function pollOrder() {
  try {
    const res = await apiFetch<{ order: any }>(`/orders/${route.params.id}`)
    const prev = order.value?.status
    order.value = res.order
    // If status changed — also refresh notifications
    if (prev && prev !== res.order.status) {
      useNotificationsStore().fetchUnreadCount()
    }
  } catch {}
}

onMounted(() => {
  // Poll order status every 3 seconds
  orderPollTimer = setInterval(pollOrder, 3000)
  // SSE = primary realtime channel (CF-Flexible-friendly). 10s polling stays
  // as a safety net for missed events on a dropped stream the SSE client
  // hasn't reconnected yet.
  appChatPoll = setInterval(() => { if (activeAppId.value) loadAppMessages() }, 10000)
  // Bind SSE: refresh the open thread instantly on any inbound chat.message.
  const sse = useSse()
  sse.onEvent((e: any) => {
    if (e?.type !== 'chat.message') return
    if (!activeAppId.value) return
    if (e.scope === 'application' && e.scope_id === activeAppId.value) {
      loadAppMessages()
    }
  })
})

// Realtime: when a chat.message event hits the user-channel for the
// currently-open application, refetch the thread immediately.
const calls = useCallsStore()
watch(() => calls.chatBus, (e: any) => {
  if (!e || !activeAppId.value) return
  if (e.scope === 'application' && e.scope_id === activeAppId.value) {
    loadAppMessages()
  }
})

onUnmounted(() => {
  if (orderPollTimer) clearInterval(orderPollTimer)
  if (appChatPoll) clearInterval(appChatPoll)
})
</script>

<style scoped>
.order-layout { display: grid; grid-template-columns: 1fr; gap: 20px; }
.order-layout .card {
  background: var(--hm-bg-1);
  border: 1px solid var(--hm-border-2);
  border-radius: 20px;
  padding: 24px;
}
.order-right { display: flex; flex-direction: column; gap: 16px; }
.oi-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; gap: 10px; }
.oi-id { font-weight: 700; color: var(--hm-text-3); font-size: 13px; }
h1 { font-size: 22px; font-weight: 700; margin-bottom: 8px; color: var(--hm-text); letter-spacing: -0.3px; }
.oi-desc { font-size: 14px; color: var(--hm-text-2); line-height: 1.6; }
.oi-details { display: flex; flex-direction: column; gap: 10px; padding: 16px 0; border-top: 1px solid var(--hm-border-2); border-bottom: 1px solid var(--hm-border-2); }
.oi-row { display: flex; align-items: center; gap: 8px; font-size: 14px; color: var(--hm-text-2); flex-wrap: wrap; }
.oi-row-muted { color: var(--hm-text-3); font-style: italic; font-size: 13px; }
.in-app-call-row {
  display: flex; align-items: center; gap: 8px;
  margin-top: 10px; padding: 10px 14px;
  background: rgba(34,197,94,0.12);
  border: 1px solid rgba(34,197,94,0.35);
  color: #22c55e; font-weight: 700; font-size: 14px;
  border-radius: 12px; cursor: pointer; width: 100%;
  transition: all 0.15s;
}
.in-app-call-row:hover { background: rgba(34,197,94,0.22); }
.in-app-call-row .icon { color: #22c55e; }
.oi-row .icon { color: var(--hm-accent); }
:global(html.theme-light) .oi-row .icon { color: #b07f00; }
.copy-btn, .maps-btn { padding: 4px; color: var(--hm-text-3); border-radius: 4px; transition: all 0.15s; background: transparent; border: 0; }
.copy-btn:hover { color: var(--hm-accent); background: var(--hm-bg-3); }
.maps-btn { color: #22c55e; }
.maps-btn:hover { background: rgba(34, 197, 94, 0.1); }

.agreed-box {
  padding: 14px 16px;
  background: rgba(255, 255, 0, 0.08);
  border: 1px solid rgba(255, 255, 0, 0.25);
  border-radius: 14px;
}
:global(html.theme-light) .agreed-box { background: rgba(177, 127, 0, 0.08); border-color: rgba(177, 127, 0, 0.3); }

.proposal-box {
  padding: 18px;
  background: rgba(255, 255, 0, 0.08);
  border: 1px solid var(--hm-accent);
  border-radius: 18px;
}
:global(html.theme-light) .proposal-box { background: rgba(177, 127, 0, 0.08); border-color: #b07f00; }
.proposal-header { display: flex; align-items: center; gap: 8px; font-size: 15px; margin-bottom: 12px; color: var(--hm-text); font-weight: 700; }
.proposal-header .icon { color: var(--hm-accent); }
.proposal-details { display: flex; flex-direction: column; gap: 6px; margin-bottom: 14px; padding: 12px; background: var(--hm-bg-2); border-radius: 12px; }
.proposal-row { display: flex; align-items: center; gap: 8px; font-size: 14px; font-weight: 500; color: var(--hm-text); }
.proposal-actions { display: flex; gap: 10px; }
.proposal-actions .btn { flex: 1; }
.agreed-title { font-weight: 700; font-size: 13px; margin-bottom: 8px; display: flex; align-items: center; gap: 6px; color: var(--hm-text); text-transform: uppercase; letter-spacing: 0.5px; }
.agreed-row { display: flex; align-items: center; gap: 8px; font-size: 14px; color: var(--hm-text-2); margin-top: 4px; }

.oi-partner {
  padding: 14px;
  background: var(--hm-bg-2);
  border: 1px solid var(--hm-border-2);
  border-radius: 14px;
}
.oi-partner-header { display: flex; align-items: center; gap: 12px; }
.oi-avatar {
  width: 44px; height: 44px; border-radius: 50%;
  background: var(--hm-accent); color: #000;
  display: flex; align-items: center; justify-content: center;
  font-weight: 700; font-size: 16px;
  background-size: cover; background-position: center;
  text-decoration: none; flex-shrink: 0;
  border: 2px solid var(--hm-accent);
}
.call-btn {
  margin-left: auto;
  display: flex; align-items: center; justify-content: center;
  width: 40px; height: 40px; border-radius: 50%;
  background: #22c55e; color: #fff;
  transition: all 0.15s; text-decoration: none;
}
.call-btn:hover { background: #16a34a; }
.partner-name { font-weight: 700; color: var(--hm-text); font-size: 14px; text-decoration: none; }
.partner-name:hover { color: var(--hm-accent); }

/* Status banners */
.status-banner {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 14px 16px;
  border-radius: 14px;
  border: 1px solid var(--hm-border-2);
  background: var(--hm-bg-2);
  color: var(--hm-text);
}
.status-banner strong { display: block; font-size: 14px; margin-bottom: 2px; color: var(--hm-text); }
.status-banner p { font-size: 13px; margin: 0; color: var(--hm-text-3); }
.sb-icon { flex-shrink: 0; color: var(--hm-accent); }
.sb-icon .icon { font-size: 22px; }

.status-banner.pending { background: rgba(255, 255, 0, 0.06); border-color: rgba(255, 255, 0, 0.2); }
.status-banner.pending .sb-icon .icon { animation: pulse-spin 2s ease-in-out infinite; }
@keyframes pulse-spin { 0%,100% { opacity: 1; } 50% { opacity: 0.5; } }

.status-banner.discussion { background: rgba(59, 130, 246, 0.08); border-color: rgba(59, 130, 246, 0.25); }
.status-banner.discussion .sb-icon { color: #60a5fa; }
.status-banner.confirmed { background: rgba(34, 197, 94, 0.08); border-color: rgba(34, 197, 94, 0.25); }
.status-banner.confirmed .sb-icon { color: #22c55e; }
.status-banner.active { background: rgba(59, 130, 246, 0.08); border-color: rgba(59, 130, 246, 0.25); }
.status-banner.active .sb-icon { color: #60a5fa; }

.oi-actions { display: flex; flex-direction: column; gap: 8px; }

/* Applications list (client) */
.apps-box {
  padding: 18px;
  background: var(--hm-bg-2);
  border: 1px solid var(--hm-border-2);
  border-radius: 18px;
}
.apps-header {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  margin-bottom: 14px;
}
.apps-header .icon { color: var(--hm-accent); font-size: 22px; }
.apps-header strong { display: block; font-size: 15px; color: var(--hm-text); margin-bottom: 2px; }
.apps-sub { font-size: 12.5px; color: var(--hm-text-3); margin: 0; line-height: 1.4; }
.apps-empty {
  text-align: center;
  padding: 28px 12px;
  color: var(--hm-text-3);
}
.apps-empty .icon { font-size: 32px; opacity: .6; }
.apps-empty p { font-size: 13px; margin: 8px 0 0; }
.apps-loading { font-size: 13px; color: var(--hm-text-3); padding: 12px; text-align: center; }
.apps-list { display: flex; flex-direction: column; gap: 10px; }
.app-card {
  display: flex;
  gap: 12px;
  padding: 14px;
  background: var(--hm-bg-1);
  border: 1px solid var(--hm-border-2);
  border-radius: 14px;
  transition: border-color .15s;
}
.app-card:hover { border-color: var(--hm-accent); }
.app-card-rejected { opacity: .55; }
.app-avatar {
  width: 44px; height: 44px; border-radius: 50%;
  background: var(--hm-accent); color: #000;
  display: flex; align-items: center; justify-content: center;
  font-weight: 700; font-size: 16px;
  background-size: cover; background-position: center;
  text-decoration: none; flex-shrink: 0;
}
.app-body { flex: 1; min-width: 0; }
.app-name-row { display: flex; justify-content: space-between; align-items: center; gap: 8px; flex-wrap: wrap; }
.app-name { font-weight: 700; font-size: 14px; color: var(--hm-text); text-decoration: none; }
.app-name:hover { color: var(--hm-accent); }
.app-rate { font-size: 12.5px; color: var(--hm-accent); font-weight: 600; }
.app-meta { font-size: 12px; color: var(--hm-text-3); margin-top: 2px; }
.app-message {
  margin-top: 8px;
  font-size: 13px;
  color: var(--hm-text-2);
  line-height: 1.5;
  font-style: italic;
  padding: 8px 10px;
  background: var(--hm-bg-2);
  border-radius: 8px;
  border-left: 3px solid var(--hm-accent);
}
.app-price {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 8px;
  font-size: 13.5px;
  color: var(--hm-text);
}
.app-price .icon { color: var(--hm-accent); }
.app-price strong { font-weight: 700; }
.app-actions { display: flex; gap: 8px; margin-top: 10px; }
.app-actions .btn { flex: 1; }
.app-status-tag {
  display: inline-block;
  margin-top: 8px;
  padding: 3px 10px;
  border-radius: 999px;
  font-size: 11.5px;
  font-weight: 600;
}
.app-status-rejected { background: rgba(239,68,68,0.12); color: #ef4444; }
.app-status-withdrawn { background: var(--hm-bg-3); color: var(--hm-text-3); }
.app-status-accepted { background: rgba(34,197,94,0.12); color: #22c55e; }
.app-status-pending { background: rgba(251,191,36,0.12); color: #eab308; }
.app-status-discussing { background: rgba(59,130,246,0.12); color: #3b82f6; }
.app-status-proposed { background: rgba(168,85,247,0.14); color: #a855f7; }

/* Tabs */
.apps-tabs {
  display: flex;
  gap: 6px;
  overflow-x: auto;
  padding: 4px 2px 12px;
  scrollbar-width: thin;
}
.apps-tab {
  flex-shrink: 0;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 6px 12px 6px 6px;
  border-radius: 999px;
  background: var(--hm-bg-1);
  border: 1px solid var(--hm-border-2);
  color: var(--hm-text-2);
  cursor: pointer;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.15s;
  position: relative;
}
.apps-tab:hover { border-color: var(--hm-accent); color: var(--hm-text); }
.apps-tab.active {
  background: var(--hm-accent);
  color: #000;
  border-color: var(--hm-accent);
}
:global(html.theme-light) .apps-tab.active { background: #b07f00; color: #fff; border-color: #b07f00; }
.apps-tab.has-proposal { border-color: #a855f7; }
.apps-tab.has-proposal.active { background: #a855f7; color: #fff; border-color: #a855f7; }
.apps-tab-avatar {
  width: 26px; height: 26px;
  border-radius: 50%;
  background: var(--hm-bg-2) center/cover no-repeat;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 11.5px;
  font-weight: 700;
  flex-shrink: 0;
}
.apps-tab-dot {
  width: 8px; height: 8px;
  background: #fff;
  border-radius: 50%;
  animation: pulse-dot 1.5s ease-in-out infinite;
}
@keyframes pulse-dot {
  0%,100% { opacity: 1; }
  50% { opacity: 0.4; }
}

/* Panel */
.apps-panel {
  padding: 16px;
  background: var(--hm-bg-1);
  border: 1px solid var(--hm-border-2);
  border-radius: 14px;
}
.apps-panel-head {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
}
.apps-panel-info { flex: 1; min-width: 0; }
.apps-panel-meta { font-size: 12px; color: var(--hm-text-3); }
.apps-panel-foot { margin-top: 12px; display: flex; gap: 8px; justify-content: flex-end; }
.reject-master-btn { color: #ef4444; border-color: rgba(239,68,68,.4); }
.reject-master-btn:hover:not(:disabled) { background: rgba(239,68,68,.1); }

/* Inline proposal in app panel */
.proposal-box-inline {
  margin: 12px 0;
  padding: 14px;
  background: rgba(168,85,247,0.08);
  border: 1px solid rgba(168,85,247,0.35);
  border-radius: 14px;
}
.proposal-box-inline .proposal-header {
  display: flex; align-items: center; gap: 8px;
  font-size: 14px; margin-bottom: 10px;
  color: var(--hm-text); font-weight: 700;
}
.proposal-box-inline .proposal-header .icon { color: #a855f7; }
.proposal-box-inline .proposal-details {
  display: flex; flex-direction: column; gap: 4px;
  margin-bottom: 12px; padding: 10px;
  background: var(--hm-bg-2); border-radius: 10px;
}
.proposal-box-inline .proposal-row {
  display: flex; align-items: center; gap: 8px;
  font-size: 13.5px; color: var(--hm-text); font-weight: 500;
}
.proposal-box-inline .proposal-actions { display: flex; gap: 8px; }
.proposal-box-inline .proposal-actions .btn { flex: 1; }

/* Chat */
.app-chat {
  margin-top: 12px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.app-chat-locked-note {
  text-align: center;
  padding: 16px;
  color: var(--hm-text-3);
  font-size: 13px;
  font-style: italic;
  background: var(--hm-bg-2);
  border-radius: 10px;
}
.app-chat-messages {
  min-height: 120px;
  max-height: 260px;
  overflow-y: auto;
  padding: 10px;
  background: var(--hm-bg-2);
  border-radius: 10px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.app-chat-hint {
  color: var(--hm-text-3);
  font-size: 12.5px;
  text-align: center;
  padding: 12px;
  font-style: italic;
}
.app-chat-msg { display: flex; flex-direction: column; align-items: flex-start; max-width: 80%; }
.app-chat-msg.mine { align-self: flex-end; align-items: flex-end; }
.app-chat-bubble {
  padding: 8px 12px;
  border-radius: 12px;
  background: var(--hm-bg-3);
  color: var(--hm-text);
  font-size: 13.5px;
  word-break: break-word;
}
.app-chat-msg.mine .app-chat-bubble {
  background: var(--hm-accent);
  color: #000;
}
:global(html.theme-light) .app-chat-msg.mine .app-chat-bubble { background: #b07f00; color: #fff; }
.app-chat-time { font-size: 10.5px; color: var(--hm-text-3); margin-top: 2px; }
.app-chat-input {
  display: flex;
  gap: 8px;
  align-items: center;
}
.app-chat-input input {
  flex: 1;
  padding: 10px 12px;
  font-size: 13.5px;
  background: var(--hm-bg-2);
  border: 1px solid var(--hm-border-2);
  border-radius: 10px;
  color: var(--hm-text);
}
.app-chat-input input:focus { outline: none; border-color: var(--hm-accent); }
.app-chat-input .btn { height: 40px; min-width: 50px; }

.apps-inactive {
  margin-top: 12px;
  font-size: 12.5px;
  color: var(--hm-text-3);
}
.apps-inactive summary {
  cursor: pointer;
  padding: 8px 0;
  font-weight: 600;
}
.apps-inactive ul { margin: 8px 0 0; padding-left: 16px; list-style: disc; }
.apps-inactive li { padding: 2px 0; }


/* Popup */
.popup-overlay {
  position: fixed; inset: 0;
  background: rgba(0, 0, 0, 0.65);
  backdrop-filter: blur(4px);
  -webkit-backdrop-filter: blur(4px);
  display: flex; align-items: center; justify-content: center;
  z-index: 1000; padding: 16px;
  animation: hm-fade-in 0.15s ease-out;
}
@keyframes hm-fade-in { from { opacity: 0; } to { opacity: 1; } }
.popup-card {
  background: var(--hm-bg-1);
  border: 1px solid var(--hm-border-2);
  border-radius: 20px;
  width: 100%; max-width: 460px;
  overflow: hidden;
  box-shadow: 0 25px 60px -10px rgba(0, 0, 0, 0.6);
  animation: hm-pop-in 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}
:global(html.theme-light) .popup-card { background: #fff; box-shadow: 0 25px 60px -10px rgba(0, 0, 0, 0.18); }
@keyframes hm-pop-in { from { opacity: 0; transform: scale(0.96); } to { opacity: 1; transform: scale(1); } }
.popup-header {
  display: flex; justify-content: space-between; align-items: center;
  padding: 18px 22px;
  border-bottom: 1px solid var(--hm-border-2);
}
.popup-header h3 {
  font-size: 17px; font-weight: 700; color: var(--hm-text);
  display: flex; align-items: center; gap: 8px;
  font-family: "Public Sans", sans-serif;
  margin: 0;
}
.popup-header h3 .icon { color: var(--hm-accent); font-size: 22px; }
:global(html.theme-light) .popup-header h3 .icon { color: #b07f00; }
.popup-header button { color: var(--hm-text-3); background: transparent; border: 0; cursor: pointer; padding: 4px; border-radius: 8px; transition: all 0.15s; }
.popup-header button:hover { color: var(--hm-text); background: var(--hm-bg-3); }
.popup-body { padding: 22px; color: var(--hm-text-2); }
.popup-footer { padding: 0 22px 22px; }

/* Date/time picker */
.time-picker { display: flex; align-items: center; gap: 8px; }
.time-select {
  width: 84px; padding: 12px; font-size: 18px; font-weight: 700;
  text-align: center;
  border: 1px solid var(--hm-border-2);
  border-radius: 12px;
  background: var(--hm-bg-2);
  color: var(--hm-text);
  appearance: none;
  -webkit-appearance: none;
  cursor: pointer;
}
.time-select:focus { border-color: var(--hm-accent); outline: 0; }
.time-sep { font-size: 22px; font-weight: 700; color: var(--hm-text-3); }
/* Duration picker */
.duration-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; }
.duration-btn {
  display: flex; flex-direction: column; align-items: center; gap: 2px;
  padding: 12px 8px;
  border: 1px solid var(--hm-border-2);
  border-radius: 12px;
  cursor: pointer; transition: all 0.15s;
  background: var(--hm-bg-2);
  color: var(--hm-text);
  font-family: inherit;
}
.duration-btn:hover { border-color: var(--hm-accent); }
.duration-btn.active {
  border-color: var(--hm-accent);
  background: rgba(255, 255, 0, 0.08);
  color: var(--hm-text);
}
:global(html.theme-light) .duration-btn.active { border-color: #b07f00; background: rgba(176, 127, 0, 0.08); }
.dur-time { font-weight: 700; font-size: 14px; }
.dur-end { font-size: 11px; color: var(--hm-text-3); }
.duration-preview,
.datetime-preview {
  display: flex; align-items: center; gap: 8px;
  padding: 12px 16px;
  background: rgba(34, 197, 94, 0.1);
  border: 1px solid rgba(34, 197, 94, 0.3);
  border-radius: 12px;
  font-size: 14px; font-weight: 600;
  color: #22c55e;
}
:global(html.theme-light) .duration-preview,
:global(html.theme-light) .datetime-preview { background: #f0fdf4; border-color: #bbf7d0; color: #166534; }
.popup-header-danger { border-bottom-color: rgba(239, 68, 68, 0.25); }
.popup-header-danger h3 { color: #ef4444; }
.popup-header-danger h3 .icon { color: #ef4444; }
.cancel-warn { font-size: 14px; color: var(--hm-text-2); line-height: 1.6; }
.cancel-footer { display: flex; gap: 10px; padding: 0 22px 22px; }

/* Problem photos */
.oi-photos-label { display: flex; align-items: center; gap: 6px; font-size: 12px; color: var(--hm-text-3); margin-bottom: 8px; font-weight: 600; letter-spacing: 0.5px; text-transform: uppercase; }
.oi-photos-grid { display: flex; flex-wrap: wrap; gap: 8px; }
.oi-photo-thumb {
  width: 76px; height: 76px; padding: 0;
  border: 1px solid var(--hm-border-2); border-radius: 12px;
  overflow: hidden; cursor: pointer; background: var(--hm-bg-2); transition: all 0.15s;
}
.oi-photo-thumb:hover { transform: scale(1.03); border-color: var(--hm-accent); }
.oi-photo-thumb img { width: 100%; height: 100%; object-fit: cover; display: block; }

/* Lightbox */
.lightbox-overlay {
  position: fixed; inset: 0; background: rgba(0,0,0,0.9); z-index: 1100;
  display: flex; align-items: center; justify-content: center; padding: 2rem;
}
.lightbox-img { max-width: 100%; max-height: 100%; object-fit: contain; border-radius: var(--radius-sm); }
.lightbox-close {
  position: absolute; top: 1rem; right: 1rem; width: 44px; height: 44px; border-radius: 50%;
  background: rgba(255,255,255,0.12); color: #fff; display: flex; align-items: center; justify-content: center;
}
.lightbox-close:hover { background: rgba(255,255,255,0.22); }
.lightbox-nav {
  position: absolute; top: 50%; transform: translateY(-50%); width: 48px; height: 48px; border-radius: 50%;
  background: rgba(255,255,255,0.12); color: #fff; display: flex; align-items: center; justify-content: center;
}
.lightbox-nav:hover { background: rgba(255,255,255,0.22); }
.lightbox-prev { left: 1rem; }
.lightbox-next { right: 1rem; }
.lightbox-counter { position: absolute; bottom: 1.5rem; left: 50%; transform: translateX(-50%); color: #fff; font-size: 0.875rem; background: rgba(0,0,0,0.5); padding: 0.375rem 0.75rem; border-radius: 999px; }

@media (min-width: 900px) {
  .order-layout { grid-template-columns: 380px 1fr; }
  .order-right { display: flex; flex-direction: column; gap: 16px; }
}
</style>
