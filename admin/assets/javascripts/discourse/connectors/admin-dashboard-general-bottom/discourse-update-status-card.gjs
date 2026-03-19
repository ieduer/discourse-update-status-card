import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import DButton from "discourse/components/d-button";
import formatDate from "discourse/helpers/format-date";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";

const CHECK_ORDER = [
  "front_proxy",
  "origin",
  "wireguard",
  "ip_passthrough",
  "sidekiq",
  "backups",
  "uploads_cdn",
];

function abbreviateMiddle(value, prefix = 14, suffix = 10) {
  if (!value || typeof value !== "string") {
    return "n/a";
  }

  if (value.length <= prefix + suffix + 3) {
    return value;
  }

  return `${value.slice(0, prefix)}...${value.slice(-suffix)}`;
}

function basename(value) {
  if (!value || typeof value !== "string") {
    return "n/a";
  }

  const trimmed = value.replace(/\/+$/, "");
  const parts = trimmed.split("/");
  return parts[parts.length - 1] || value;
}

function compactSha(value) {
  if (!value || typeof value !== "string") {
    return "n/a";
  }

  return /^[0-9a-f]{16,}$/i.test(value) ? value.slice(0, 12) : value;
}

export default class DiscourseUpdateStatusCard extends Component {
  @tracked loading = false;
  @tracked response = null;
  @tracked error = null;

  static shouldRender(args, context) {
    return context.siteSettings.discourse_update_status_card_enabled;
  }

  get payload() {
    return this.response?.payload || {};
  }

  get summary() {
    return this.payload.summary || {};
  }

  get live() {
    return this.payload.live || {};
  }

  get official() {
    return this.payload.official || {};
  }

  get reports() {
    return this.payload.reports || {};
  }

  get meta() {
    return this.payload.meta || {};
  }

  get notes() {
    return Array.isArray(this.payload.notes) ? this.payload.notes : [];
  }

  get hasPayload() {
    return Object.keys(this.payload).length > 0;
  }

  get reviewState() {
    return this.summary.review_state || "unknown";
  }

  get reviewStateLabel() {
    return (
      this.summary.review_label ||
      i18n(`discourse_update_status_card.states.${this.reviewState}`)
    );
  }

  get commitGapDisplay() {
    return this.summary.commit_gap ?? "n/a";
  }

  get recommendationDisplay() {
    return this.summary.window_recommendation || "n/a";
  }

  get liveDescribeDisplay() {
    return this.live.describe || "n/a";
  }

  get liveCoreShaDisplay() {
    return this.live.core_sha || "n/a";
  }

  get liveDockerShaDisplay() {
    return this.live.docker_sha || "n/a";
  }

  get officialDescribeDisplay() {
    return this.official.describe || "n/a";
  }

  get officialCoreShaDisplay() {
    return this.official.core_sha || "n/a";
  }

  get officialDockerShaDisplay() {
    return this.official.docker_sha || "n/a";
  }

  get reportPathDisplay() {
    return this.reports.latest_report_path || "n/a";
  }

  get sourcePathDisplay() {
    return this.meta.source_path || "n/a";
  }

  get versionBlocks() {
    return [
      {
        key: "live",
        title: i18n("discourse_update_status_card.live"),
        rows: [
          {
            key: "describe",
            label: i18n("discourse_update_status_card.fields.describe"),
            value: this.liveDescribeDisplay,
            displayValue: this.liveDescribeDisplay,
            code: true,
          },
          {
            key: "core_sha",
            label: i18n("discourse_update_status_card.fields.core_sha"),
            value: this.liveCoreShaDisplay,
            displayValue: compactSha(this.liveCoreShaDisplay),
            code: true,
          },
          {
            key: "docker_sha",
            label: i18n("discourse_update_status_card.fields.docker_sha"),
            value: this.liveDockerShaDisplay,
            displayValue: compactSha(this.liveDockerShaDisplay),
            code: true,
          },
        ],
      },
      {
        key: "official",
        title: i18n("discourse_update_status_card.official"),
        rows: [
          {
            key: "describe",
            label: i18n("discourse_update_status_card.fields.describe"),
            value: this.officialDescribeDisplay,
            displayValue: this.officialDescribeDisplay,
            code: true,
          },
          {
            key: "core_sha",
            label: i18n("discourse_update_status_card.fields.core_sha"),
            value: this.officialCoreShaDisplay,
            displayValue: compactSha(this.officialCoreShaDisplay),
            code: true,
          },
          {
            key: "docker_sha",
            label: i18n("discourse_update_status_card.fields.docker_sha"),
            value: this.officialDockerShaDisplay,
            displayValue: compactSha(this.officialDockerShaDisplay),
            code: true,
          },
        ],
      },
    ];
  }

  get reportEntries() {
    return [
      {
        key: "report",
        label: i18n("discourse_update_status_card.latest_report_path"),
        fullValue: this.reportPathDisplay,
        displayValue: basename(this.reportPathDisplay),
      },
      {
        key: "source",
        label: i18n("discourse_update_status_card.source_path"),
        fullValue: this.sourcePathDisplay,
        displayValue: basename(this.sourcePathDisplay),
      },
    ];
  }

  get checkEntries() {
    const checks = this.payload.checks || {};
    const keys = [
      ...CHECK_ORDER.filter((key) => checks[key]),
      ...Object.keys(checks).filter((key) => !CHECK_ORDER.includes(key)),
    ];

    return keys.map((key) => {
      const check = checks[key] || {};
      const state = check.state || "unknown";

      return {
        key,
        label:
          check.label ||
          i18n(`discourse_update_status_card.checks_map.${key}`),
        summary:
          check.summary ||
          i18n(`discourse_update_status_card.states.${state}`),
        detail: check.detail,
        compactDetail: abbreviateMiddle(check.detail, 56, 18),
        state,
      };
    });
  }

  @action
  async loadStatus() {
    this.loading = true;
    this.error = null;

    try {
      const response = await ajax(
        "/admin/plugins/discourse-update-status-card/status.json",
        { ignoreUnsent: false }
      );

      this.response = response;
      if (!response.ok) {
        this.error =
          response.error || i18n("discourse_update_status_card.unavailable");
      }
    } catch (error) {
      this.error =
        error?.jqXHR?.responseJSON?.error ||
        error?.message ||
        i18n("discourse_update_status_card.unavailable");
    } finally {
      this.loading = false;
    }
  }

  @action
  refresh() {
    this.loadStatus();
  }

  <template>
    <section
      class="admin-dashboard-general-bottom-outlet discourse-update-status-card"
      {{didInsert this.loadStatus}}
    >
      <div class="update-status-card__header">
        <div>
          <h2>{{i18n "discourse_update_status_card.title"}}</h2>
          <p>{{i18n "discourse_update_status_card.subtitle"}}</p>
        </div>

        <DButton
          @action={{this.refresh}}
          @icon="rotate-right"
          @label="discourse_update_status_card.refresh"
          class="btn-default"
        />
      </div>

      <p class="update-status-card__notice">
        {{i18n "discourse_update_status_card.read_only_notice"}}
      </p>

      {{#if this.loading}}
        <div class="update-status-card__alert" data-state="unknown">
          {{i18n "discourse_update_status_card.loading"}}
        </div>
      {{/if}}

      {{#if this.error}}
        <div class="update-status-card__alert" data-state="warn">
          <strong>{{i18n "discourse_update_status_card.unavailable"}}</strong>
          <span>{{this.error}}</span>
        </div>
      {{/if}}

      {{#if this.hasPayload}}
        <div class="update-status-card__summary-grid">
          <div
            class="summary-item summary-item--state"
            data-state={{this.reviewState}}
          >
            <span class="summary-label">
              {{i18n "discourse_update_status_card.review_state"}}
            </span>
            <strong class="summary-value">{{this.reviewStateLabel}}</strong>
          </div>

          <div class="summary-item">
            <span class="summary-label">
              {{i18n "discourse_update_status_card.commit_gap"}}
            </span>
            <strong class="summary-value">{{this.commitGapDisplay}}</strong>
          </div>

          <div class="summary-item">
            <span class="summary-label">
              {{i18n "discourse_update_status_card.last_checked_at"}}
            </span>
            <strong class="summary-value">
              {{#if this.summary.last_checked_at}}
                {{formatDate this.summary.last_checked_at leaveAgo="true"}}
              {{else}}
                n/a
              {{/if}}
            </strong>
          </div>

          <div class="summary-item summary-item--recommendation">
            <span class="summary-label">
              {{i18n "discourse_update_status_card.recommendation"}}
            </span>
            <p class="summary-copy">{{this.recommendationDisplay}}</p>
          </div>
        </div>

        <div class="update-status-card__versions">
          {{#each this.versionBlocks as |block|}}
            <div class="version-block" data-kind={{block.key}}>
              <div class="version-block__header">
                <h3>{{block.title}}</h3>
              </div>

              <dl>
                {{#each block.rows as |row|}}
                  <div class="version-row">
                    <dt>{{row.label}}</dt>
                    <dd title={{row.value}}>
                      {{#if row.code}}
                        <code>{{row.displayValue}}</code>
                      {{else}}
                        {{row.displayValue}}
                      {{/if}}
                    </dd>
                  </div>
                {{/each}}
              </dl>
            </div>
          {{/each}}
        </div>

        <div class="update-status-card__checks">
          <h3>{{i18n "discourse_update_status_card.checks"}}</h3>

          <div class="checks-grid">
            {{#each this.checkEntries as |check|}}
              <div class="check-item" data-state={{check.state}}>
                <div class="check-header">
                  <strong>{{check.label}}</strong>
                  <span class="check-status" data-state={{check.state}}>
                    {{check.summary}}
                  </span>
                </div>
                {{#if check.detail}}
                  <p class="check-detail" title={{check.detail}}>
                    {{check.compactDetail}}
                  </p>
                {{/if}}
              </div>
            {{/each}}
          </div>
        </div>

        <div class="update-status-card__reports">
          <h3>{{i18n "discourse_update_status_card.reports"}}</h3>
          <div class="report-list">
            {{#each this.reportEntries as |entry|}}
              <div class="report-item">
                <span class="summary-label">{{entry.label}}</span>
                <strong>{{entry.displayValue}}</strong>
                <code title={{entry.fullValue}}>{{entry.fullValue}}</code>
              </div>
            {{/each}}
          </div>
        </div>

        <div class="update-status-card__notes">
          <h3>{{i18n "discourse_update_status_card.notes"}}</h3>
          {{#if this.notes.length}}
            <ul>
              {{#each this.notes as |note|}}
                <li>{{note}}</li>
              {{/each}}
            </ul>
          {{else}}
            <p>{{i18n "discourse_update_status_card.no_notes"}}</p>
          {{/if}}
        </div>
      {{/if}}
    </section>
  </template>
}
