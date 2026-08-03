import 'package:flutter/material.dart';

enum AppLocale { en, zh }

const kLocaleKey = 'app_locale';

class AppLocalizations {
  final AppLocale locale;

  AppLocalizations(this.locale);

  static const _strings = <String, Map<AppLocale, String>>{
    // Login
    'login': {AppLocale.en: 'Login', AppLocale.zh: '登录'},
    'login_failed': {AppLocale.en: 'Login failed', AppLocale.zh: '登录失败'},
    'invalid_server_url': {
      AppLocale.en: 'Enter a valid server URL',
      AppLocale.zh: '请输入有效的服务器地址',
    },
    'server_url': {AppLocale.en: 'Server URL', AppLocale.zh: '服务器地址'},
    'username': {AppLocale.en: 'Username', AppLocale.zh: '用户名'},
    'password': {AppLocale.en: 'Password', AppLocale.zh: '密码'},
    'required': {AppLocale.en: 'Required', AppLocale.zh: '必填'},
    'llm_api_manager': {
      AppLocale.en: 'LLM API Manager',
      AppLocale.zh: 'LLM API 管理器',
    },

    // Nav
    'home': {AppLocale.en: 'Home', AppLocale.zh: '首页'},
    'channels': {AppLocale.en: 'Channels', AppLocale.zh: '渠道'},
    'groups': {AppLocale.en: 'Groups', AppLocale.zh: '分组'},
    'models': {AppLocale.en: 'Models', AppLocale.zh: '模型'},
    'api_keys': {AppLocale.en: 'API Keys', AppLocale.zh: 'API Key'},
    'logs': {AppLocale.en: 'Logs', AppLocale.zh: '日志'},
    'settings': {AppLocale.en: 'Settings', AppLocale.zh: '设置'},
    'users': {AppLocale.en: 'Users', AppLocale.zh: '用户'},
    'ops': {AppLocale.en: 'Ops', AppLocale.zh: '运维'},

    // Dashboard
    'dashboard': {AppLocale.en: 'Dashboard', AppLocale.zh: '仪表盘'},
    'dashboard_subtitle': {
      AppLocale.en:
          'Keep track of traffic, cost, and channel activity at a glance',
      AppLocale.zh: '快速查看流量、费用与渠道活跃情况',
    },
    'today': {AppLocale.en: 'Today', AppLocale.zh: '今日'},
    'total': {AppLocale.en: 'Total', AppLocale.zh: '总计'},
    'requests': {AppLocale.en: 'Requests', AppLocale.zh: '请求数'},
    'failed': {AppLocale.en: 'Failed', AppLocale.zh: '失败'},
    'cost': {AppLocale.en: 'Cost', AppLocale.zh: '费用'},
    'tokens': {AppLocale.en: 'Tokens', AppLocale.zh: 'Token数'},
    'success_rate': {AppLocale.en: 'Success Rate', AppLocale.zh: '成功率'},
    'avg_wait': {AppLocale.en: 'Avg Wait', AppLocale.zh: '平均等待'},
    'running': {AppLocale.en: 'Running', AppLocale.zh: '运行中'},
    'batches': {AppLocale.en: 'Batches', AppLocale.zh: '批次'},
    'started_at': {AppLocale.en: 'Started', AppLocale.zh: '开始时间'},
    'updated_at': {AppLocale.en: 'Updated', AppLocale.zh: '更新时间'},
    'heartbeat_at': {AppLocale.en: 'Heartbeat', AppLocale.zh: '心跳时间'},
    'daily_requests': {AppLocale.en: 'Daily Requests', AppLocale.zh: '每日请求'},
    'daily_cost': {AppLocale.en: 'Daily Cost', AppLocale.zh: '每日费用'},
    'daily_chart': {AppLocale.en: 'Daily Trend', AppLocale.zh: '每日趋势'},
    'daily_chart_subtitle': {
      AppLocale.en: 'Compare request volume and spending changes over time',
      AppLocale.zh: '对比请求量与费用的每日变化趋势',
    },

    // Ranking
    'ranking': {AppLocale.en: 'Ranking', AppLocale.zh: '排行榜'},
    'ranking_subtitle': {
      AppLocale.en: 'Review the most active channels and API keys by metric',
      AppLocale.zh: '按指标查看最活跃的渠道与 API Key',
    },
    'sort_by_cost': {AppLocale.en: 'Cost', AppLocale.zh: '费用'},
    'sort_by_count': {AppLocale.en: 'Count', AppLocale.zh: '请求数'},
    'sort_by_tokens': {AppLocale.en: 'Tokens', AppLocale.zh: 'Token数'},
    'sort_by_key_usage': {AppLocale.en: 'Key Usage', AppLocale.zh: 'Key 用量'},
    'api_key_leaderboard': {
      AppLocale.en: 'API Key Leaderboard',
      AppLocale.zh: 'API Key 排行',
    },
    'no_data': {AppLocale.en: 'No data', AppLocale.zh: '暂无数据'},
    'success_rate_label': {AppLocale.en: 'Success Rate', AppLocale.zh: '成功率'},
    'channel_leaderboard': {
      AppLocale.en: 'Channel Leaderboard',
      AppLocale.zh: '渠道排行',
    },
    'show_more': {AppLocale.en: 'Show more', AppLocale.zh: '展开更多'},
    'show_more_count': {
      AppLocale.en: '+{count} more',
      AppLocale.zh: '还有 {count} 项',
    },
    'show_less': {AppLocale.en: 'Show less', AppLocale.zh: '收起'},
    'collapse': {AppLocale.en: 'Collapse', AppLocale.zh: '收起'},
    'token_consumption_ranking': {
      AppLocale.en: 'Token Consumption',
      AppLocale.zh: 'Token 消耗排行',
    },
    'request_activity_ranking': {
      AppLocale.en: 'Request Activity',
      AppLocale.zh: '请求活跃度排行',
    },
    'key_usage_ranking': {AppLocale.en: 'Key Usage', AppLocale.zh: 'Key 用量排行'},
    'input': {AppLocale.en: 'Input', AppLocale.zh: '输入'},

    // Wait time unit
    'wait_time_unit': {AppLocale.en: 'Wait Time Unit', AppLocale.zh: '等待时间单位'},
    'wait_time_unit_ms': {AppLocale.en: 'Milliseconds', AppLocale.zh: '毫秒'},
    'wait_time_unit_s': {AppLocale.en: 'Seconds', AppLocale.zh: '秒'},
    'wait_time_unit_auto': {AppLocale.en: 'Auto', AppLocale.zh: '自动'},

    // Channel
    'api_key': {AppLocale.en: 'API Key', AppLocale.zh: 'API Key'},
    'keys': {AppLocale.en: 'Keys', AppLocale.zh: '密钥'},
    'success': {AppLocale.en: 'Success', AppLocale.zh: '成功'},
    'delete_channel': {AppLocale.en: 'Delete Channel', AppLocale.zh: '删除渠道'},
    'delete_confirm': {
      AppLocale.en: 'Delete "{name}"?',
      AppLocale.zh: '删除 "{name}"？',
    },
    'cancel': {AppLocale.en: 'Cancel', AppLocale.zh: '取消'},
    'delete': {AppLocale.en: 'Delete', AppLocale.zh: '删除'},
    'no_channels': {AppLocale.en: 'No channels', AppLocale.zh: '暂无渠道'},
    'channels_subtitle': {
      AppLocale.en: 'Manage your LLM API channels',
      AppLocale.zh: '管理您的 LLM API 渠道',
    },
    'no_groups': {AppLocale.en: 'No groups', AppLocale.zh: '暂无分组'},
    'groups_subtitle': {
      AppLocale.en: 'Organize channels into groups',
      AppLocale.zh: '将渠道组织成分组',
    },
    'no_api_keys': {AppLocale.en: 'No API keys', AppLocale.zh: '暂无 API Key'},
    'api_keys_subtitle': {
      AppLocale.en: 'Manage API keys for external access',
      AppLocale.zh: '管理外部访问的 API Key',
    },
    'no_logs': {AppLocale.en: 'No logs', AppLocale.zh: '暂无日志'},
    'logs_subtitle': {
      AppLocale.en: 'View request and response logs',
      AppLocale.zh: '查看请求和响应日志',
    },
    'create_first_channel': {
      AppLocale.en: 'Create your first channel to get started',
      AppLocale.zh: '创建您的第一个渠道以开始',
    },
    'create_first_group': {
      AppLocale.en: 'Create your first group to organize channels',
      AppLocale.zh: '创建您的第一个分组来组织渠道',
    },
    'no_models': {AppLocale.en: 'No models', AppLocale.zh: '暂无模型'},
    'create_first_model': {
      AppLocale.en: 'Create your first model pricing entry',
      AppLocale.zh: '创建第一条模型价格记录',
    },
    'create_first_api_key': {
      AppLocale.en: 'Create your first API key for external access',
      AppLocale.zh: '创建您的第一个 API Key 用于外部访问',
    },
    'create_channel': {AppLocale.en: 'Create Channel', AppLocale.zh: '创建渠道'},
    'edit_channel': {AppLocale.en: 'Edit Channel', AppLocale.zh: '编辑渠道'},
    'channel_name': {AppLocale.en: 'Channel Name', AppLocale.zh: '渠道名称'},
    'channel_type': {AppLocale.en: 'Channel Type', AppLocale.zh: '渠道类型'},
    'base_url': {AppLocale.en: 'Base URL', AppLocale.zh: '基础URL'},
    'base_urls': {AppLocale.en: 'Base URLs', AppLocale.zh: '基础地址'},
    'model': {AppLocale.en: 'Model', AppLocale.zh: '模型'},
    'custom_model': {AppLocale.en: 'Custom Model', AppLocale.zh: '自定义模型'},
    'create_model': {AppLocale.en: 'Create Model', AppLocale.zh: '创建模型'},
    'edit_model': {AppLocale.en: 'Edit Model', AppLocale.zh: '编辑模型'},
    'delete_model': {AppLocale.en: 'Delete Model', AppLocale.zh: '删除模型'},
    'model_name': {AppLocale.en: 'Model Name', AppLocale.zh: '模型名称'},
    'input_price': {AppLocale.en: 'Input Price', AppLocale.zh: '输入价格'},
    'output_price': {AppLocale.en: 'Output Price', AppLocale.zh: '输出价格'},
    'cache_read_price': {
      AppLocale.en: 'Cache Read Price',
      AppLocale.zh: '缓存读取价格',
    },
    'cache_write_price': {
      AppLocale.en: 'Cache Write Price',
      AppLocale.zh: '缓存写入价格',
    },
    'cache_read_price_short': {AppLocale.en: 'Cache Read', AppLocale.zh: '缓存读'},
    'cache_write_price_short': {
      AppLocale.en: 'Cache Write',
      AppLocale.zh: '缓存写',
    },
    'linked_channels': {AppLocale.en: 'Linked Channels', AppLocale.zh: '关联渠道'},
    'sync_prices': {AppLocale.en: 'Sync Prices', AppLocale.zh: '同步价格'},
    'model_price_sync_success': {
      AppLocale.en: 'Model prices synchronized successfully',
      AppLocale.zh: '模型价格同步成功',
    },
    'model_price_sync_failed': {
      AppLocale.en: 'Failed to synchronize model prices',
      AppLocale.zh: '模型价格同步失败',
    },
    'enabled': {AppLocale.en: 'Enabled', AppLocale.zh: '启用'},
    'proxy': {AppLocale.en: 'Proxy', AppLocale.zh: '代理'},
    'auto_sync': {AppLocale.en: 'Auto Sync', AppLocale.zh: '自动同步'},
    'sync_channels': {AppLocale.en: 'Sync Channels', AppLocale.zh: '同步渠道'},
    'channel_sync_success': {
      AppLocale.en: 'Channel synchronization completed',
      AppLocale.zh: '渠道同步完成',
    },
    'channel_sync_failed': {
      AppLocale.en: 'Channel synchronization failed',
      AppLocale.zh: '渠道同步失败',
    },
    'fetch_models': {AppLocale.en: 'Fetch Models', AppLocale.zh: '抓取模型'},
    'fetch_models_success': {
      AppLocale.en: 'Fetched models successfully',
      AppLocale.zh: '抓取模型成功',
    },
    'fetch_models_failed': {
      AppLocale.en: 'Failed to fetch models',
      AppLocale.zh: '抓取模型失败',
    },
    'fetch_models_empty': {
      AppLocale.en: 'No models were returned',
      AppLocale.zh: '未返回任何模型',
    },
    'test_channel': {AppLocale.en: 'Test Channel', AppLocale.zh: '测试渠道'},
    'test_channel_passed': {
      AppLocale.en: 'Channel test passed',
      AppLocale.zh: '渠道测试通过',
    },
    'test_channel_failed': {
      AppLocale.en: 'Channel test failed',
      AppLocale.zh: '渠道测试失败',
    },
    'advanced_settings': {
      AppLocale.en: 'Advanced Settings',
      AppLocale.zh: '高级设置',
    },
    'channel_proxy': {AppLocale.en: 'Channel Proxy', AppLocale.zh: '渠道代理'},
    'param_override': {AppLocale.en: 'Param Override', AppLocale.zh: '参数覆盖'},
    'custom_headers': {AppLocale.en: 'Custom Headers', AppLocale.zh: '自定义请求头'},
    'custom_header_ops': {AppLocale.en: 'Header Override Ops', AppLocale.zh: '请求头改写规则'},
    'auto_group': {AppLocale.en: 'Auto Group', AppLocale.zh: '自动分组'},
    'auto_group_none': {AppLocale.en: 'Disabled', AppLocale.zh: '关闭'},
    'auto_group_fuzzy': {AppLocale.en: 'Fuzzy', AppLocale.zh: '模糊匹配'},
    'auto_group_exact': {AppLocale.en: 'Exact', AppLocale.zh: '精确匹配'},
    'auto_group_regex': {AppLocale.en: 'Regex', AppLocale.zh: '正则匹配'},
    'remark': {AppLocale.en: 'Remark', AppLocale.zh: '备注'},

    // Group
    'first_token_timeout': {
      AppLocale.en: 'First Token Timeout',
      AppLocale.zh: '首Token超时',
    },
    'token_timeout': {AppLocale.en: 'Token Timeout', AppLocale.zh: 'Token 超时'},
    'keep_time': {AppLocale.en: 'Keep Time', AppLocale.zh: '保持时间'},
    'expand': {AppLocale.en: 'Expand', AppLocale.zh: '展开'},
    'session_keep': {AppLocale.en: 'Session Keep', AppLocale.zh: '会话保持'},
    'delete_group': {AppLocale.en: 'Delete Group', AppLocale.zh: '删除分组'},
    'create_group': {AppLocale.en: 'Create Group', AppLocale.zh: '创建分组'},
    'edit_group': {AppLocale.en: 'Edit Group', AppLocale.zh: '编辑分组'},
    'group_name': {AppLocale.en: 'Group Name', AppLocale.zh: '分组名称'},
    'mode': {AppLocale.en: 'Mode', AppLocale.zh: '模式'},
    'match_regex': {AppLocale.en: 'Match Regex', AppLocale.zh: '匹配正则'},
    'group_items': {AppLocale.en: 'Group Items', AppLocale.zh: '分组项'},
    'channel_id': {AppLocale.en: 'Channel ID', AppLocale.zh: '渠道ID'},
    'priority': {AppLocale.en: 'Priority', AppLocale.zh: '优先级'},
    'weight': {AppLocale.en: 'Weight', AppLocale.zh: '权重'},

    // API Key
    'create_api_key': {
      AppLocale.en: 'Create API Key',
      AppLocale.zh: '创建 API Key',
    },
    'edit_api_key': {AppLocale.en: 'Edit API Key', AppLocale.zh: '编辑 API Key'},
    'name': {AppLocale.en: 'Name', AppLocale.zh: '名称'},
    'create': {AppLocale.en: 'Create', AppLocale.zh: '创建'},
    'api_key_created': {
      AppLocale.en: 'API Key Created',
      AppLocale.zh: 'API Key 已创建',
    },
    'ok': {AppLocale.en: 'OK', AppLocale.zh: '确定'},
    'delete_api_key': {
      AppLocale.en: 'Delete API Key',
      AppLocale.zh: '删除 API Key',
    },
    'max_cost': {AppLocale.en: 'Max Cost', AppLocale.zh: '最大费用'},
    'expire_at': {AppLocale.en: 'Expire At', AppLocale.zh: '过期时间'},
    'expire_at_hint': {
      AppLocale.en: 'Unix timestamp, 0 = never',
      AppLocale.zh: 'Unix 时间戳, 0 = 永不过期',
    },
    'supported_models': {
      AppLocale.en: 'Supported Models',
      AppLocale.zh: '支持的模型',
    },
    'supported_models_hint': {
      AppLocale.en: 'Empty = all models',
      AppLocale.zh: '留空 = 所有模型',
    },
    'rate_limit_rpm': {AppLocale.en: 'Rate Limit RPM', AppLocale.zh: 'RPM 限制'},
    'rate_limit_tpm': {AppLocale.en: 'Rate Limit TPM', AppLocale.zh: 'TPM 限制'},
    'per_model_quota': {
      AppLocale.en: 'Per-Model Quota JSON',
      AppLocale.zh: '单模型配额 JSON',
    },
    // Phase 1.2: Security fields
    'allowed_ips': {
      AppLocale.en: 'Allowed IPs (comma-separated)',
      AppLocale.zh: 'IP 白名单（逗号分隔）',
    },
    'tags': {AppLocale.en: 'Tags (comma-separated)', AppLocale.zh: '标签（逗号分隔）'},
    'excluded_channels': {
      AppLocale.en: 'Excluded Channel IDs (comma-separated)',
      AppLocale.zh: '排除渠道 ID（逗号分隔）',
    },

    // Log
    'clear_logs': {AppLocale.en: 'Clear Logs', AppLocale.zh: '清除日志'},
    'clear_logs_confirm': {
      AppLocale.en: 'Delete all relay logs? This cannot be undone.',
      AppLocale.zh: '删除所有转发日志？此操作不可恢复。',
    },
    'clear': {AppLocale.en: 'Clear', AppLocale.zh: '清除'},
    'load_more': {AppLocale.en: 'Load More', AppLocale.zh: '加载更多'},

    // Setting
    'server_version': {AppLocale.en: 'Server Version', AppLocale.zh: '服务器版本'},
    'language': {AppLocale.en: 'Language', AppLocale.zh: '语言'},
    'language_english': {AppLocale.en: 'English', AppLocale.zh: '英文'},
    'language_chinese': {AppLocale.en: 'Chinese', AppLocale.zh: '中文'},
    'empty': {AppLocale.en: '(empty)', AppLocale.zh: '(空)'},
    'save': {AppLocale.en: 'Save', AppLocale.zh: '保存'},
    'settings_subtitle': {
      AppLocale.en: 'Configure app and server settings',
      AppLocale.zh: '配置应用和服务器设置',
    },
    'preferences': {AppLocale.en: 'Preferences', AppLocale.zh: '偏好设置'},
    'server_settings': {AppLocale.en: 'Server Settings', AppLocale.zh: '服务器设置'},
    'enter_value': {AppLocale.en: 'Enter value', AppLocale.zh: '输入值'},
    'account_settings': {AppLocale.en: 'Account', AppLocale.zh: '账户设置'},
    'change_username': {AppLocale.en: 'Change Username', AppLocale.zh: '修改用户名'},
    'change_password': {AppLocale.en: 'Change Password', AppLocale.zh: '修改密码'},
    'old_password': {AppLocale.en: 'Old Password', AppLocale.zh: '旧密码'},
    'new_password': {AppLocale.en: 'New Password', AppLocale.zh: '新密码'},
    'new_username': {AppLocale.en: 'New Username', AppLocale.zh: '新用户名'},
    'username_updated': {
      AppLocale.en: 'Username updated. Please log in again.',
      AppLocale.zh: '用户名已更新，请重新登录。',
    },
    'password_updated': {
      AppLocale.en: 'Password updated. Please log in again.',
      AppLocale.zh: '密码已更新，请重新登录。',
    },
    'backup_restore': {AppLocale.en: 'Backup', AppLocale.zh: '备份恢复'},
    'export_data': {AppLocale.en: 'Export JSON', AppLocale.zh: '导出 JSON'},
    'import_data': {AppLocale.en: 'Import JSON', AppLocale.zh: '导入 JSON'},
    'include_logs': {AppLocale.en: 'Include Logs', AppLocale.zh: '包含日志'},
    'include_stats': {AppLocale.en: 'Include Stats', AppLocale.zh: '包含统计'},
    'paste_import_json': {
      AppLocale.en: 'Paste exported JSON',
      AppLocale.zh: '粘贴导出的 JSON',
    },
    'export_success': {AppLocale.en: 'Export ready', AppLocale.zh: '导出内容已生成'},
    'import_success': {AppLocale.en: 'Import completed', AppLocale.zh: '导入完成'},
    'latest_version': {AppLocale.en: 'Latest Version', AppLocale.zh: '最新版本'},
    'update_available': {
      AppLocale.en: 'Update available',
      AppLocale.zh: '有可用更新',
    },
    'up_to_date': {AppLocale.en: 'Up to date', AppLocale.zh: '已是最新版本'},
    'update_now': {AppLocale.en: 'Update Now', AppLocale.zh: '立即更新'},
    'updating': {AppLocale.en: 'Updating...', AppLocale.zh: '更新中...'},
    'update_started': {
      AppLocale.en: 'Update started. Refresh after the service restarts.',
      AppLocale.zh: '更新已开始，服务重启后请刷新。',
    },
    'update_check_failed': {
      AppLocale.en: 'Failed to check updates',
      AppLocale.zh: '检查更新失败',
    },
    'change_action': {AppLocale.en: 'Change', AppLocale.zh: '修改'},
    'app_preferences': {AppLocale.en: 'App Preferences', AppLocale.zh: '应用偏好'},
    'auto_refresh': {AppLocale.en: 'Auto Refresh', AppLocale.zh: '自动刷新'},
    'refresh_interval': {
      AppLocale.en: 'Refresh Interval',
      AppLocale.zh: '刷新间隔',
    },
    'logout_action': {AppLocale.en: 'Log Out', AppLocale.zh: '退出登录'},
    'logout_subtitle': {
      AppLocale.en: 'Clear the current session and return to the login screen.',
      AppLocale.zh: '清除当前会话并返回登录页。',
    },

    // Overview
    'overview': {AppLocale.en: 'Overview', AppLocale.zh: '概览'},

    // Channel types
    'type_openai_chat': {
      AppLocale.en: 'OpenAI Chat',
      AppLocale.zh: 'OpenAI Chat',
    },
    'type_openai_response': {
      AppLocale.en: 'OpenAI Response',
      AppLocale.zh: 'OpenAI Response',
    },
    'type_openai_embedding': {
      AppLocale.en: 'OpenAI Embedding',
      AppLocale.zh: 'OpenAI Embedding',
    },
    'type_anthropic': {AppLocale.en: 'Anthropic', AppLocale.zh: 'Anthropic'},
    'type_gemini': {AppLocale.en: 'Gemini', AppLocale.zh: 'Gemini'},
    'type_volcengine': {AppLocale.en: 'Volcengine', AppLocale.zh: '火山引擎'},
    'type_mimo': {AppLocale.en: 'Mimo', AppLocale.zh: 'Mimo'},
    'type_unknown': {AppLocale.en: 'Type {type}', AppLocale.zh: '类型 {type}'},

    // Group modes
    'mode_round_robin': {AppLocale.en: 'Round Robin', AppLocale.zh: '轮询'},
    'mode_random': {AppLocale.en: 'Random', AppLocale.zh: '随机'},
    'mode_failover': {AppLocale.en: 'Failover', AppLocale.zh: '故障转移'},
    'mode_weighted': {AppLocale.en: 'Weighted', AppLocale.zh: '加权'},
    'mode_auto': {AppLocale.en: 'Auto', AppLocale.zh: '自动'},
    'endpoint_type': {AppLocale.en: 'API Category', AppLocale.zh: 'API 分类'},
    'endpoint_all': {AppLocale.en: 'All', AppLocale.zh: '全部'},
    'endpoint_chat': {AppLocale.en: 'Chat', AppLocale.zh: '对话'},
    'endpoint_embeddings': {
      AppLocale.en: 'Embeddings',
      AppLocale.zh: 'Embeddings',
    },
    'endpoint_rerank': {AppLocale.en: 'Rerank', AppLocale.zh: 'Rerank'},
    'endpoint_moderations': {AppLocale.en: 'Moderations', AppLocale.zh: '审核'},
    'endpoint_image_generation': {
      AppLocale.en: 'Image Generation',
      AppLocale.zh: '图片生成',
    },
    'endpoint_audio_speech': {
      AppLocale.en: 'Audio Speech',
      AppLocale.zh: '语音合成',
    },
    'endpoint_audio_transcription': {
      AppLocale.en: 'Audio Transcription',
      AppLocale.zh: '音频转写',
    },
    'endpoint_video_generation': {
      AppLocale.en: 'Video Generation',
      AppLocale.zh: '视频生成',
    },
    'endpoint_music_generation': {
      AppLocale.en: 'Music Generation',
      AppLocale.zh: '音乐生成',
    },
    'endpoint_search': {AppLocale.en: 'Search', AppLocale.zh: '搜索'},
    'add': {AppLocale.en: 'Add', AppLocale.zh: '添加'},
    'auto_group_models': {AppLocale.en: 'Auto Group', AppLocale.zh: '自动分组'},
    'auto_group_confirm_title': {
      AppLocale.en: 'Auto group models?',
      AppLocale.zh: '自动分组模型？',
    },
    'auto_group_confirm_content': {
      AppLocale.en:
          'This will scan model-channel mappings and create missing groups automatically.',
      AppLocale.zh: '这会扫描模型与渠道映射，并自动创建缺失的分组。',
    },
    'auto_group_success': {
      AppLocale.en: 'Auto group completed',
      AppLocale.zh: '自动分组完成',
    },
    'auto_group_failed': {
      AppLocale.en: 'Auto group failed',
      AppLocale.zh: '自动分组失败',
    },
    'auto_group_summary': {
      AppLocale.en: 'Auto Group Summary',
      AppLocale.zh: '自动分组摘要',
    },
    'created': {AppLocale.en: 'Created', AppLocale.zh: '已创建'},
    'skipped': {AppLocale.en: 'Skipped', AppLocale.zh: '已跳过'},
    'selected_models': {AppLocale.en: 'Selected Models', AppLocale.zh: '已选模型'},
    'available_models': {
      AppLocale.en: 'Available Models',
      AppLocale.zh: '可选模型',
    },
    'search_models': {
      AppLocale.en: 'Search model or channel',
      AppLocale.zh: '搜索模型或渠道',
    },
    'no_matching_models': {
      AppLocale.en: 'No matching models',
      AppLocale.zh: '没有匹配的模型',
    },
    'auto_add': {AppLocale.en: 'Auto Add', AppLocale.zh: '自动添加'},
    'clear_selection': {AppLocale.en: 'Clear', AppLocale.zh: '清空'},
    'test_group': {AppLocale.en: 'Test Group', AppLocale.zh: '测试分组'},
    'test_group_passed': {
      AppLocale.en: 'Group test passed',
      AppLocale.zh: '分组测试通过',
    },
    'test_group_failed': {
      AppLocale.en: 'Group test failed',
      AppLocale.zh: '分组测试失败',
    },
    'test_group_request_failed': {
      AppLocale.en: 'Failed to test group',
      AppLocale.zh: '分组测试失败',
    },
    'regex_invalid': {AppLocale.en: 'Invalid regex', AppLocale.zh: '正则表达式无效'},
    'channel_model': {AppLocale.en: 'Channel / Model', AppLocale.zh: '渠道 / 模型'},
    'move_up': {AppLocale.en: 'Move up', AppLocale.zh: '上移'},
    'move_down': {AppLocale.en: 'Move down', AppLocale.zh: '下移'},
    'disabled': {AppLocale.en: 'Disabled', AppLocale.zh: '禁用'},

    // Setting labels
    'setting_proxy_url': {AppLocale.en: 'Proxy URL', AppLocale.zh: '代理 URL'},
    'setting_stats_save_interval': {
      AppLocale.en: 'Stats Save Interval (min)',
      AppLocale.zh: '统计保存间隔 (分钟)',
    },
    'setting_model_info_update_interval': {
      AppLocale.en: 'Model Info Update Interval (hr)',
      AppLocale.zh: '模型信息更新间隔 (小时)',
    },
    'setting_sync_llm_interval': {
      AppLocale.en: 'LLM Sync Interval (hr)',
      AppLocale.zh: 'LLM 同步间隔 (小时)',
    },
    'setting_relay_log_keep_period': {
      AppLocale.en: 'Log Keep Period (days)',
      AppLocale.zh: '日志保留天数',
    },
    'setting_relay_log_keep_enabled': {
      AppLocale.en: 'Keep Logs Enabled',
      AppLocale.zh: '保留历史日志',
    },
    'setting_cors_allow_origins': {
      AppLocale.en: 'CORS Allow Origins',
      AppLocale.zh: 'CORS 允许来源',
    },
    'setting_relay_retry_count': {
      AppLocale.en: 'Relay Retry Count',
      AppLocale.zh: '转发重试次数',
    },
    'setting_circuit_breaker_threshold': {
      AppLocale.en: 'Circuit Breaker Threshold',
      AppLocale.zh: '熔断触发阈值',
    },
    'setting_circuit_breaker_cooldown': {
      AppLocale.en: 'Circuit Breaker Cooldown (sec)',
      AppLocale.zh: '熔断冷却时间 (秒)',
    },
    'setting_circuit_breaker_max_cooldown': {
      AppLocale.en: 'Circuit Breaker Max Cooldown (sec)',
      AppLocale.zh: '熔断最大冷却时间 (秒)',
    },
    'setting_public_api_base_url': {
      AppLocale.en: 'Public API Base URL',
      AppLocale.zh: '对外 API 基础地址',
    },
    'setting_ratelimit_cooldown': {
      AppLocale.en: 'Rate Limit Cooldown (sec)',
      AppLocale.zh: '限流冷却时间 (秒)',
    },
    'setting_relay_max_total_attempts': {
      AppLocale.en: 'Max Total Attempts',
      AppLocale.zh: '最大总尝试次数',
    },
    'setting_auto_strategy_min_samples': {
      AppLocale.en: 'Auto Min Samples',
      AppLocale.zh: 'Auto 最小样本数',
    },
    'setting_auto_strategy_time_window': {
      AppLocale.en: 'Auto Time Window (sec)',
      AppLocale.zh: 'Auto 时间窗口 (秒)',
    },
    'setting_auto_strategy_sample_threshold': {
      AppLocale.en: 'Auto Sample Threshold',
      AppLocale.zh: 'Auto 样本窗口阈值',
    },
    'setting_auto_strategy_latency_weight': {
      AppLocale.en: 'Auto Latency Weight',
      AppLocale.zh: 'Auto 延迟权重',
    },
    'setting_alert_notify_language': {
      AppLocale.en: 'Alert Language',
      AppLocale.zh: '告警通知语言',
    },
    'setting_semantic_cache_enabled': {
      AppLocale.en: 'Semantic Cache',
      AppLocale.zh: '语义缓存开关',
    },
    'setting_semantic_cache_embedding_base_url': {
      AppLocale.en: 'Cache Embedding Base URL',
      AppLocale.zh: '缓存 Embedding 地址',
    },
    'setting_semantic_cache_embedding_model': {
      AppLocale.en: 'Cache Embedding Model',
      AppLocale.zh: '缓存 Embedding 模型',
    },
    'setting_semantic_cache_embedding_api_key': {
      AppLocale.en: 'Cache Embedding API Key',
      AppLocale.zh: '缓存 Embedding Key',
    },
    'setting_semantic_cache_similarity_threshold': {
      AppLocale.en: 'Cache Similarity Threshold',
      AppLocale.zh: '缓存相似度阈值',
    },
    'setting_semantic_cache_ttl_seconds': {
      AppLocale.en: 'Cache TTL (sec)',
      AppLocale.zh: '缓存 TTL (秒)',
    },
    'setting_semantic_cache_max_entries': {
      AppLocale.en: 'Cache Max Entries',
      AppLocale.zh: '缓存最大条目数',
    },
    'setting_semantic_cache_embedding_dimensions': {
      AppLocale.en: 'Cache Embedding Dimensions',
      AppLocale.zh: '缓存 Embedding 维度',
    },
    'setting_ai_route_group_id': {
      AppLocale.en: 'AI Route Target Group',
      AppLocale.zh: 'AI Route 目标分组',
    },
    'setting_ai_route_base_url': {
      AppLocale.en: 'AI Route Base URL',
      AppLocale.zh: 'AI Route Base URL',
    },
    'setting_ai_route_api_key': {
      AppLocale.en: 'AI Route API Key',
      AppLocale.zh: 'AI Route API Key',
    },
    'setting_ai_route_model': {
      AppLocale.en: 'AI Route Model',
      AppLocale.zh: 'AI Route 模型',
    },
    'setting_ai_route_timeout_seconds': {
      AppLocale.en: 'AI Route Timeout (sec)',
      AppLocale.zh: 'AI Route 超时 (秒)',
    },
    'setting_ai_route_parallelism': {
      AppLocale.en: 'AI Route Parallelism',
      AppLocale.zh: 'AI Route 并发数',
    },
    'setting_ai_route_services': {
      AppLocale.en: 'AI Route Services',
      AppLocale.zh: 'AI Route 服务池',
    },
    'not_set': {AppLocale.en: 'Not set', AppLocale.zh: '未设置'},
    'never': {AppLocale.en: 'Never', AppLocale.zh: '从未'},
    'channel_fallback_name': {
      AppLocale.en: 'Channel {id}',
      AppLocale.zh: '渠道 {id}',
    },
    'api_key_fallback_name': {
      AppLocale.en: 'Key #{id}',
      AppLocale.zh: 'Key #{id}',
    },
    'attempt': {AppLocale.en: 'Attempt', AppLocale.zh: '尝试'},
    'last_sync_time': {AppLocale.en: 'Last Sync', AppLocale.zh: '上次同步'},
    'last_update_time': {AppLocale.en: 'Last Update', AppLocale.zh: '上次更新'},
    'sync_now': {AppLocale.en: 'Sync now', AppLocale.zh: '立即同步'},
    'llm_sync_settings': {AppLocale.en: 'LLM Sync', AppLocale.zh: 'LLM 同步'},
    'llm_price_settings': {AppLocale.en: 'LLM Price', AppLocale.zh: '模型价格'},
    'retry_settings': {AppLocale.en: 'Retry', AppLocale.zh: '重试策略'},
    'circuit_breaker_settings': {
      AppLocale.en: 'Circuit Breaker',
      AppLocale.zh: '熔断',
    },
    'auto_strategy_settings': {
      AppLocale.en: 'Auto Strategy',
      AppLocale.zh: 'Auto 策略',
    },
    'route_group_danger': {
      AppLocale.en: 'Route Group Danger',
      AppLocale.zh: '分组危险操作',
    },
    'delete_all_groups': {
      AppLocale.en: 'Delete All Groups',
      AppLocale.zh: '删除全部分组',
    },
    'delete_all_groups_confirm': {
      AppLocale.en: 'Delete all {count} groups? This cannot be undone.',
      AppLocale.zh: '删除全部 {count} 个分组？此操作不可恢复。',
    },
    'delete_all_groups_success': {
      AppLocale.en: 'All groups deleted successfully.',
      AppLocale.zh: '全部分组已删除。',
    },
    'route_group_count': {
      AppLocale.en: '{count} groups currently stored',
      AppLocale.zh: '当前共有 {count} 个分组',
    },
    'ai_route': {AppLocale.en: 'AI Route', AppLocale.zh: 'AI Route'},
    'ai_route_settings': {
      AppLocale.en: 'AI Route Settings',
      AppLocale.zh: 'AI Route 设置',
    },
    'ai_route_target_group': {
      AppLocale.en: 'Target Group',
      AppLocale.zh: '目标分组',
    },
    'ai_route_target_group_hint': {
      AppLocale.en: 'Used as the destination group for generated routes.',
      AppLocale.zh: 'AI Route 生成结果优先写入该分组。',
    },
    'ai_route_base_url': {AppLocale.en: 'Base URL', AppLocale.zh: '基础地址'},
    'ai_route_api_key': {AppLocale.en: 'API Key', AppLocale.zh: 'API Key'},
    'ai_route_model': {AppLocale.en: 'Model', AppLocale.zh: '模型'},
    'ai_route_timeout_seconds': {AppLocale.en: 'Timeout', AppLocale.zh: '超时时间'},
    'ai_route_parallelism': {AppLocale.en: 'Parallelism', AppLocale.zh: '并发数'},
    'ai_route_services': {
      AppLocale.en: 'Service Pool JSON',
      AppLocale.zh: '服务池 JSON',
    },
    'ai_route_services_hint': {
      AppLocale.en:
          'Paste a JSON array of service configs. Empty input will be saved as [].',
      AppLocale.zh: '粘贴服务配置 JSON 数组；留空会保存为 []。',
    },
    'ai_route_services_invalid_json': {
      AppLocale.en: 'AI Route services must be a valid JSON array.',
      AppLocale.zh: 'AI Route 服务池必须是合法的 JSON 数组。',
    },
    'ai_route_services_count': {
      AppLocale.en: '{count} services',
      AppLocale.zh: '{count} 个服务',
    },
    'ai_route_generate_table': {
      AppLocale.en: 'Generate All Routes',
      AppLocale.zh: '生成全部路由',
    },
    'ai_route_generate_group': {
      AppLocale.en: 'Generate Group Route',
      AppLocale.zh: '生成分组路由',
    },
    'ai_route_confirm_title': {
      AppLocale.en: 'Start AI Route generation?',
      AppLocale.zh: '开始 AI Route 生成？',
    },
    'ai_route_confirm_table': {
      AppLocale.en:
          'This will analyze model-channel mappings and write route groups automatically.',
      AppLocale.zh: '这会分析模型与渠道映射，并自动写入分组路由。',
    },
    'ai_route_confirm_group': {
      AppLocale.en: 'Generate AI Route for "{name}"?',
      AppLocale.zh: '为 "{name}" 生成 AI Route？',
    },
    'ai_route_start_failed': {
      AppLocale.en: 'Failed to start AI Route',
      AppLocale.zh: '启动 AI Route 失败',
    },
    'ai_route_progress_title': {
      AppLocale.en: 'AI Route Progress',
      AppLocale.zh: 'AI Route 进度',
    },
    'ai_route_scope_table': {AppLocale.en: 'Table scope', AppLocale.zh: '全局范围'},
    'ai_route_scope_group': {
      AppLocale.en: 'Group scope',
      AppLocale.zh: '单分组范围',
    },
    'ai_route_status_queued': {AppLocale.en: 'Queued', AppLocale.zh: '排队中'},
    'ai_route_status_running': {AppLocale.en: 'Running', AppLocale.zh: '执行中'},
    'ai_route_status_completed': {
      AppLocale.en: 'Completed',
      AppLocale.zh: '已完成',
    },
    'ai_route_status_failed': {AppLocale.en: 'Failed', AppLocale.zh: '失败'},
    'ai_route_status_timeout': {AppLocale.en: 'Timeout', AppLocale.zh: '超时'},
    'ai_route_step_queued': {AppLocale.en: 'Queued', AppLocale.zh: '排队中'},
    'ai_route_step_collecting_models': {
      AppLocale.en: 'Collecting models',
      AppLocale.zh: '收集模型',
    },
    'ai_route_step_building_batches': {
      AppLocale.en: 'Building batches',
      AppLocale.zh: '构建批次',
    },
    'ai_route_step_analyzing_batches': {
      AppLocale.en: 'Analyzing batches',
      AppLocale.zh: '分析批次',
    },
    'ai_route_step_parsing_response': {
      AppLocale.en: 'Parsing response',
      AppLocale.zh: '解析响应',
    },
    'ai_route_step_validating_routes': {
      AppLocale.en: 'Validating routes',
      AppLocale.zh: '校验路由',
    },
    'ai_route_step_writing_groups': {
      AppLocale.en: 'Writing groups',
      AppLocale.zh: '写入分组',
    },
    'ai_route_step_finalizing': {
      AppLocale.en: 'Finalizing',
      AppLocale.zh: '收尾中',
    },
    'ai_route_step_completed': {AppLocale.en: 'Completed', AppLocale.zh: '已完成'},
    'ai_route_step_failed': {AppLocale.en: 'Failed', AppLocale.zh: '失败'},
    'ai_route_step_timeout': {AppLocale.en: 'Timeout', AppLocale.zh: '超时'},
    'ai_route_current_batch': {
      AppLocale.en: 'Current Batches',
      AppLocale.zh: '当前批次',
    },
    'ai_route_service': {AppLocale.en: 'Service', AppLocale.zh: '服务'},
    'ai_route_result_group': {
      AppLocale.en:
          'Generated {routes} routes and {items} items for the group.',
      AppLocale.zh: '已为该分组生成 {routes} 条路由、{items} 个条目。',
    },
    'ai_route_result_table': {
      AppLocale.en:
          'Generated {routes} routes across {groups} groups with {items} items.',
      AppLocale.zh: '已在 {groups} 个分组中生成 {routes} 条路由、{items} 个条目。',
    },

    // Bootstrap
    'initial_setup': {AppLocale.en: 'Initial Setup', AppLocale.zh: '初始设置'},
    'create_admin_account': {
      AppLocale.en: 'Create the initial admin account',
      AppLocale.zh: '创建初始管理员账户',
    },
    'confirm_password': {
      AppLocale.en: 'Confirm Password',
      AppLocale.zh: '确认密码',
    },
    'create_admin': {AppLocale.en: 'Create Admin', AppLocale.zh: '创建管理员'},
    'admin_created': {
      AppLocale.en: 'Admin account created successfully',
      AppLocale.zh: '管理员账户创建成功',
    },
    'bootstrap_failed': {
      AppLocale.en: 'Failed to create admin account',
      AppLocale.zh: '创建管理员账户失败',
    },
    'password_min_length': {
      AppLocale.en: 'Password must be at least 12 characters',
      AppLocale.zh: '密码至少需要12个字符',
    },
    'password_mismatch': {
      AppLocale.en: 'Passwords do not match',
      AppLocale.zh: '两次密码不一致',
    },
    'password_too_short': {
      AppLocale.en: 'Password must be at least 12 characters',
      AppLocale.zh: '密码至少需要12个字符',
    },
    'remember_me': {AppLocale.en: 'Remember me', AppLocale.zh: '记住我'},

    // Misc
    'second': {AppLocale.en: 's', AppLocale.zh: '秒'},
    'hour_unit': {AppLocale.en: 'hr', AppLocale.zh: '小时'},
    'select_channel': {AppLocale.en: 'Select Channel', AppLocale.zh: '选择渠道'},
    'load_channels_failed': {
      AppLocale.en: 'Failed to load channels',
      AppLocale.zh: '加载渠道失败',
    },
    'collapse_text': {AppLocale.en: 'Collapse', AppLocale.zh: '收起'},

    // Users
    'no_users': {AppLocale.en: 'No users', AppLocale.zh: '暂无用户'},
    'create_first_user': {
      AppLocale.en: 'Create the first user account',
      AppLocale.zh: '创建第一个用户账户',
    },
    'create_user': {AppLocale.en: 'Create User', AppLocale.zh: '创建用户'},
    'delete_user': {AppLocale.en: 'Delete User', AppLocale.zh: '删除用户'},
    'change_role': {AppLocale.en: 'Change Role', AppLocale.zh: '修改角色'},
    'change_role_for': {
      AppLocale.en: 'Change role for {name}',
      AppLocale.zh: '修改 {name} 的角色',
    },
    'current_role': {
      AppLocale.en: 'Current role: {role}',
      AppLocale.zh: '当前角色：{role}',
    },
    'role': {AppLocale.en: 'Role', AppLocale.zh: '角色'},
    'role_admin': {AppLocale.en: 'Admin', AppLocale.zh: '管理员'},
    'role_editor': {AppLocale.en: 'Editor', AppLocale.zh: '编辑者'},
    'role_viewer': {AppLocale.en: 'Viewer', AppLocale.zh: '观察者'},

    // Ops
    'ops_system': {AppLocale.en: 'System', AppLocale.zh: '系统信息'},
    'ops_health': {AppLocale.en: 'Health', AppLocale.zh: '健康状态'},
    'ops_cache': {AppLocale.en: 'Semantic Cache', AppLocale.zh: '语义缓存'},
    'ops_quota': {AppLocale.en: 'API Key Quota', AppLocale.zh: 'Key 配额总览'},
    'ops_db_status': {AppLocale.en: 'Database', AppLocale.zh: '数据库'},
    'ops_cache_status': {AppLocale.en: 'Cache', AppLocale.zh: '缓存'},
    'ops_task_status': {AppLocale.en: 'Task Runtime', AppLocale.zh: '后台任务'},
    'ops_ok': {AppLocale.en: 'OK', AppLocale.zh: '正常'},
    'ops_fail': {AppLocale.en: 'FAIL', AppLocale.zh: '异常'},
    'ops_healthy_groups': {AppLocale.en: 'Healthy Groups', AppLocale.zh: '健康分组'},
    'ops_warning_groups': {AppLocale.en: 'Warning Groups', AppLocale.zh: '警告分组'},
    'ops_degraded_groups': {AppLocale.en: 'Degraded Groups', AppLocale.zh: '降级分组'},
    'ops_down_groups': {AppLocale.en: 'Down Groups', AppLocale.zh: '宕机分组'},
    'ops_empty_groups': {AppLocale.en: 'Empty Groups', AppLocale.zh: '空分组'},
    'ops_cache_entries': {AppLocale.en: 'Entries', AppLocale.zh: '条目数'},
    'ops_cache_hits': {AppLocale.en: 'Hits', AppLocale.zh: '命中'},
    'ops_cache_misses': {AppLocale.en: 'Misses', AppLocale.zh: '未命中'},
    'ops_cache_hit_rate': {AppLocale.en: 'Hit Rate', AppLocale.zh: '命中率'},
    'ops_cache_usage_rate': {AppLocale.en: 'Usage Rate', AppLocale.zh: '使用率'},
    'ops_total_keys': {AppLocale.en: 'Total Keys', AppLocale.zh: 'Key 总数'},
    'ops_enabled_keys': {AppLocale.en: 'Enabled', AppLocale.zh: '已启用'},
    'ops_available_keys': {AppLocale.en: 'Available', AppLocale.zh: '可用'},
    'ops_expired_keys': {AppLocale.en: 'Expired', AppLocale.zh: '已过期'},
    'ops_limited_keys': {AppLocale.en: 'Rate-Limited', AppLocale.zh: '被限流'},
    'ops_exhausted_keys': {AppLocale.en: 'Exhausted', AppLocale.zh: '配额耗尽'},
    'ops_total_rpm': {AppLocale.en: 'Total RPM', AppLocale.zh: 'RPM 合计'},
    'ops_total_tpm': {AppLocale.en: 'Total TPM', AppLocale.zh: 'TPM 合计'},
    'ops_build_time': {AppLocale.en: 'Build Time', AppLocale.zh: '构建时间'},
    'database_type': {AppLocale.en: 'Database', AppLocale.zh: '数据库类型'},

    // Ops Telemetry
    'ops_telemetry': {AppLocale.en: 'Telemetry', AppLocale.zh: '遥测数据'},
    'ops_overview': {AppLocale.en: 'Overview', AppLocale.zh: '概览'},
    'ops_uptime': {AppLocale.en: 'Uptime', AppLocale.zh: '运行时间'},
    'ops_total_requests': {AppLocale.en: 'Total Requests', AppLocale.zh: '总请求数'},
    'ops_avg_latency': {AppLocale.en: 'Avg Latency', AppLocale.zh: '平均延迟'},
    'ops_error_rate': {AppLocale.en: 'Error Rate', AppLocale.zh: '错误率'},
    'ops_active_connections': {AppLocale.en: 'Active Connections', AppLocale.zh: '活跃连接'},
    'ops_memory_usage': {AppLocale.en: 'Memory Usage', AppLocale.zh: '内存使用'},
    'ops_runtime_signals': {AppLocale.en: 'Runtime Signals', AppLocale.zh: '运行时信号'},
    'ops_goroutine_count': {AppLocale.en: 'Goroutines', AppLocale.zh: '协程数'},
    'ops_gc_pause': {AppLocale.en: 'GC Pause', AppLocale.zh: 'GC 暂停'},
    'ops_heap_alloc': {AppLocale.en: 'Heap Alloc', AppLocale.zh: '堆分配'},
    'ops_heap_in_use': {AppLocale.en: 'Heap In Use', AppLocale.zh: '堆使用中'},
    'ops_db_latency': {AppLocale.en: 'DB Latency', AppLocale.zh: '数据库延迟'},
    'ops_db_connections': {AppLocale.en: 'DB Connections', AppLocale.zh: '数据库连接'},
    'ops_db_connected': {AppLocale.en: 'Connected', AppLocale.zh: '已连接'},
    'ops_session_quota': {AppLocale.en: 'Session & Quota', AppLocale.zh: '会话与配额'},
    'ops_active_sessions': {AppLocale.en: 'Active Sessions', AppLocale.zh: '活跃会话'},
    'ops_quota_exhausted': {AppLocale.en: 'Quota Exhausted', AppLocale.zh: '配额耗尽'},
    'ops_recent_quota_events': {AppLocale.en: 'Recent Quota Events', AppLocale.zh: '近期配额事件'},
    'ops_prompt_cache': {AppLocale.en: 'Prompt Cache', AppLocale.zh: '提示缓存'},
    'ops_cache_evictions': {AppLocale.en: 'Evictions', AppLocale.zh: '淘汰数'},
    'ops_provider_health': {AppLocale.en: 'Provider Health', AppLocale.zh: '供应商健康'},
    'ops_total_providers': {AppLocale.en: 'Total', AppLocale.zh: '总数'},
    'ops_healthy_providers': {AppLocale.en: 'Healthy', AppLocale.zh: '健康'},
    'ops_degraded_providers': {AppLocale.en: 'Degraded', AppLocale.zh: '降级'},
    'ops_down_providers': {AppLocale.en: 'Down', AppLocale.zh: '宕机'},
    'ops_provider_name': {AppLocale.en: 'Provider', AppLocale.zh: '供应商'},
    'ops_provider_status': {AppLocale.en: 'Status', AppLocale.zh: '状态'},
    'ops_provider_latency': {AppLocale.en: 'Latency', AppLocale.zh: '延迟'},
    'ops_provider_error_rate': {AppLocale.en: 'Error Rate', AppLocale.zh: '错误率'},
    'ops_provider_last_check': {AppLocale.en: 'Last Check', AppLocale.zh: '最后检查'},
    'ops_sort_by': {AppLocale.en: 'Sort by', AppLocale.zh: '排序方式'},
    'ops_hero_metrics': {AppLocale.en: 'Hero Metrics', AppLocale.zh: '关键指标'},

    // Alerts
    'alerts': {AppLocale.en: 'Alerts', AppLocale.zh: '告警'},
    'no_alert_rules': {AppLocale.en: 'No alert rules', AppLocale.zh: '暂无告警规则'},
    'create_first_alert_rule': {AppLocale.en: 'Create your first alert rule', AppLocale.zh: '创建第一条告警规则'},
    'alert_rules': {AppLocale.en: 'Rules', AppLocale.zh: '规则'},
    'alert_channels': {AppLocale.en: 'Channels', AppLocale.zh: '通知渠道'},
    'alert_history': {AppLocale.en: 'History', AppLocale.zh: '历史'},
    'create_alert_rule': {AppLocale.en: 'Create Alert Rule', AppLocale.zh: '创建告警规则'},
    'edit_alert_rule': {AppLocale.en: 'Edit Alert Rule', AppLocale.zh: '编辑告警规则'},
    'alert_condition': {AppLocale.en: 'Condition', AppLocale.zh: '条件'},
    'alert_threshold': {AppLocale.en: 'Threshold', AppLocale.zh: '阈值'},
    'alert_cooldown': {AppLocale.en: 'Cooldown (sec)', AppLocale.zh: '冷却时间 (秒)'},
    'alert_condition_json': {AppLocale.en: 'Condition JSON', AppLocale.zh: '条件 JSON'},
    'alert_notif_channel': {AppLocale.en: 'Notify Channel', AppLocale.zh: '通知渠道'},
    'no_alert_channels': {AppLocale.en: 'No notification channels', AppLocale.zh: '暂无通知渠道'},
    'create_first_alert_channel': {AppLocale.en: 'Create a notification channel first', AppLocale.zh: '请先创建通知渠道'},
    'no_alert_history': {AppLocale.en: 'No alert history', AppLocale.zh: '暂无告警历史'},
    'create_alert_channel': {AppLocale.en: 'Create Channel', AppLocale.zh: '创建通知渠道'},
    'edit_alert_channel': {AppLocale.en: 'Edit Channel', AppLocale.zh: '编辑通知渠道'},
    'model_market': {AppLocale.en: 'Model Market', AppLocale.zh: '模型市场'},
    'market_summary': {AppLocale.en: 'Market Summary', AppLocale.zh: '市场总览'},
    'coverage': {AppLocale.en: 'Coverage', AppLocale.zh: '覆盖'},
    'latency': {AppLocale.en: 'Avg Latency', AppLocale.zh: '平均延迟'},
    'market_channel_count': {AppLocale.en: 'Channels', AppLocale.zh: '渠道数'},
    'market_key_count': {AppLocale.en: 'Keys', AppLocale.zh: 'Key数'},
    'cache_evaluation': {AppLocale.en: 'Cache Evaluation', AppLocale.zh: '缓存评估'},
    'evaluated_requests': {AppLocale.en: 'Evaluated', AppLocale.zh: '已评估'},
    'cache_hit_responses': {AppLocale.en: 'Cache Hits', AppLocale.zh: '缓存命中'},
    'cache_miss_requests': {AppLocale.en: 'Cache Misses', AppLocale.zh: '缓存未命中'},
    'bypassed_requests': {AppLocale.en: 'Bypassed', AppLocale.zh: '被跳过'},
    'stored_responses': {AppLocale.en: 'Stored', AppLocale.zh: '已存储'},

    // Analytics
    'analytics': {AppLocale.en: 'Analytics', AppLocale.zh: '分析'},
    'analytics_overview': {AppLocale.en: 'Overview', AppLocale.zh: '概览'},
    'analytics_providers': {AppLocale.en: 'Providers', AppLocale.zh: '供应商'},
    'analytics_models': {AppLocale.en: 'Models', AppLocale.zh: '模型'},
    'analytics_group_health': {AppLocale.en: 'Group Health', AppLocale.zh: '分组健康'},
    'analytics_fallback_rate': {AppLocale.en: 'Fallback Rate', AppLocale.zh: '降级率'},
    'analytics_range': {AppLocale.en: 'Time Range', AppLocale.zh: '时间范围'},
    'analytics_range_1d': {AppLocale.en: '1 Day', AppLocale.zh: '1天'},
    'analytics_range_7d': {AppLocale.en: '7 Days', AppLocale.zh: '7天'},
    'analytics_range_30d': {AppLocale.en: '30 Days', AppLocale.zh: '30天'},
    'analytics_range_90d': {AppLocale.en: '90 Days', AppLocale.zh: '90天'},
    'analytics_channel_model': {AppLocale.en: 'Channel×Model', AppLocale.zh: '渠道×模型'},
    'analytics_route_health': {AppLocale.en: 'Route Health', AppLocale.zh: '路由健康'},
    'analytics_latency': {AppLocale.en: 'Latency', AppLocale.zh: '延迟'},
    'analytics_evaluation': {AppLocale.en: 'Evaluation', AppLocale.zh: '评估'},
    'analytics_cache': {AppLocale.en: 'Cache', AppLocale.zh: '缓存'},
    'analytics_avg_latency': {AppLocale.en: 'Avg Latency', AppLocale.zh: '平均延迟'},
    'analytics_p50': {AppLocale.en: 'P50', AppLocale.zh: 'P50'},
    'analytics_p95': {AppLocale.en: 'P95', AppLocale.zh: 'P95'},
    'analytics_p99': {AppLocale.en: 'P99', AppLocale.zh: 'P99'},
    'analytics_distribution': {AppLocale.en: 'Distribution', AppLocale.zh: '分布'},
    'analytics_request_count': {AppLocale.en: 'Requests', AppLocale.zh: '请求数'},
    'analytics_failing_channels': {AppLocale.en: 'Failing Channels', AppLocale.zh: '失败渠道'},
    'analytics_auto_strategy': {AppLocale.en: 'Auto Strategy', AppLocale.zh: '自动策略'},
    'analytics_best_channel': {AppLocale.en: 'Best Channel', AppLocale.zh: '最佳渠道'},
    'analytics_best_score': {AppLocale.en: 'Best Score', AppLocale.zh: '最佳分数'},
    'analytics_reason': {AppLocale.en: 'Reason', AppLocale.zh: '原因'},

    // Audit
    'audit_logs': {AppLocale.en: 'Audit Logs', AppLocale.zh: '审计日志'},
    'no_audit_logs': {AppLocale.en: 'No audit logs', AppLocale.zh: '暂无审计日志'},
    'audit_action': {AppLocale.en: 'Action', AppLocale.zh: '操作'},
    'audit_target': {AppLocale.en: 'Target', AppLocale.zh: '目标'},
    'audit_method': {AppLocale.en: 'Method', AppLocale.zh: '方法'},
    'audit_status': {AppLocale.en: 'Status', AppLocale.zh: '状态码'},

    // Site
    'site': {AppLocale.en: 'Site', AppLocale.zh: '站点'},
    'sites': {AppLocale.en: 'Sites', AppLocale.zh: '站点'},
    'create_site': {AppLocale.en: 'Create Site', AppLocale.zh: '创建站点'},
    'edit_site': {AppLocale.en: 'Edit Site', AppLocale.zh: '编辑站点'},
    'delete_site': {AppLocale.en: 'Delete Site', AppLocale.zh: '删除站点'},
    'site_platform': {AppLocale.en: 'Platform', AppLocale.zh: '平台'},
    'site_base_url': {AppLocale.en: 'Base URL', AppLocale.zh: '基础地址'},
    'site_auth_type': {AppLocale.en: 'Auth Type', AppLocale.zh: '认证类型'},
    'site_status_active': {AppLocale.en: 'Active', AppLocale.zh: '活跃'},
    'site_status_inactive': {AppLocale.en: 'Inactive', AppLocale.zh: '未激活'},
    'site_status_error': {AppLocale.en: 'Error', AppLocale.zh: '错误'},
    'site_status_archived': {AppLocale.en: 'Archived', AppLocale.zh: '已归档'},
    'site_accounts': {AppLocale.en: 'Accounts', AppLocale.zh: '账户'},
    'site_tokens': {AppLocale.en: 'Tokens', AppLocale.zh: '令牌'},
    'site_models': {AppLocale.en: 'Models', AppLocale.zh: '模型'},
    'site_sync': {AppLocale.en: 'Sync', AppLocale.zh: '同步'},
    'site_enable': {AppLocale.en: 'Enable', AppLocale.zh: '启用'},
    'site_disable': {AppLocale.en: 'Disable', AppLocale.zh: '禁用'},
    'site_archive': {AppLocale.en: 'Archive', AppLocale.zh: '归档'},
    'site_restore': {AppLocale.en: 'Restore', AppLocale.zh: '恢复'},
    'site_detect': {AppLocale.en: 'Detect', AppLocale.zh: '检测'},
    'site_batch_update': {AppLocale.en: 'Batch Update', AppLocale.zh: '批量更新'},
    'no_sites': {AppLocale.en: 'No sites', AppLocale.zh: '暂无站点'},
    'sites_subtitle': {
      AppLocale.en: 'Manage your Hub sites',
      AppLocale.zh: '管理您的 Hub 站点',
    },
    'create_first_site': {
      AppLocale.en: 'Create your first site to get started',
      AppLocale.zh: '创建您的第一个站点以开始',
    },
    'site_name': {AppLocale.en: 'Site Name', AppLocale.zh: '站点名称'},
    'site_proxy_enabled': {AppLocale.en: 'Proxy Enabled', AppLocale.zh: '启用代理'},
    'site_proxy_url': {AppLocale.en: 'Proxy URL', AppLocale.zh: '代理地址'},
    'site_channel_count': {AppLocale.en: 'Channels', AppLocale.zh: '渠道数'},
    'site_model_count': {AppLocale.en: 'Models', AppLocale.zh: '模型数'},
    'site_total_cost': {AppLocale.en: 'Total Cost', AppLocale.zh: '总费用'},
    'site_total_requests': {AppLocale.en: 'Requests', AppLocale.zh: '请求数'},
    'site_success_rate': {AppLocale.en: 'Success Rate', AppLocale.zh: '成功率'},
    'site_last_sync': {AppLocale.en: 'Last Sync', AppLocale.zh: '上次同步'},
    'site_error_message': {AppLocale.en: 'Error', AppLocale.zh: '错误信息'},
    'site_search_hint': {
      AppLocale.en: 'Search sites...',
      AppLocale.zh: '搜索站点...',
    },
    'site_filter_all': {AppLocale.en: 'All', AppLocale.zh: '全部'},
    'site_filter_active': {AppLocale.en: 'Active', AppLocale.zh: '活跃'},
    'site_filter_inactive': {AppLocale.en: 'Inactive', AppLocale.zh: '未激活'},
    'site_filter_error': {AppLocale.en: 'Error', AppLocale.zh: '错误'},
    'site_confirm_delete': {
      AppLocale.en: 'Delete site "{name}"?',
      AppLocale.zh: '删除站点 "{name}"？',
    },
    'site_confirm_archive': {
      AppLocale.en: 'Archive site "{name}"?',
      AppLocale.zh: '归档站点 "{name}"？',
    },
    'site_confirm_restore': {
      AppLocale.en: 'Restore site "{name}"?',
      AppLocale.zh: '恢复站点 "{name}"？',
    },
    'site_detect_hint': {
      AppLocale.en: 'Enter base URL to auto-detect site configuration',
      AppLocale.zh: '输入基础地址以自动检测站点配置',
    },
    'site_oauth_client_id': {AppLocale.en: 'OAuth Client ID', AppLocale.zh: 'OAuth 客户端 ID'},
    'site_oauth_client_secret': {AppLocale.en: 'OAuth Client Secret', AppLocale.zh: 'OAuth 客户端密钥'},
    'site_oauth_token_url': {AppLocale.en: 'OAuth Token URL', AppLocale.zh: 'OAuth Token 地址'},
    'site_account_balance': {AppLocale.en: 'Balance', AppLocale.zh: '余额'},
    'site_account_total_spent': {AppLocale.en: 'Total Spent', AppLocale.zh: '已消费'},
    'site_account_plan': {AppLocale.en: 'Plan', AppLocale.zh: '套餐'},
    'site_account_request_limit': {AppLocale.en: 'Request Limit', AppLocale.zh: '请求限制'},
    'site_account_requests_used': {AppLocale.en: 'Requests Used', AppLocale.zh: '已用请求'},
    'site_account_expires_at': {AppLocale.en: 'Expires', AppLocale.zh: '过期时间'},
    'site_token_masked': {AppLocale.en: 'Token', AppLocale.zh: '令牌'},
    'site_token_expires': {AppLocale.en: 'Expires', AppLocale.zh: '过期时间'},
    'site_model_provider': {AppLocale.en: 'Provider', AppLocale.zh: '供应商'},
    'site_model_input_price': {AppLocale.en: 'Input Price', AppLocale.zh: '输入价格'},
    'site_model_output_price': {AppLocale.en: 'Output Price', AppLocale.zh: '输出价格'},
    'site_model_context_window': {AppLocale.en: 'Context Window', AppLocale.zh: '上下文窗口'},

    // Site Sync
    'site_sync_all': {AppLocale.en: 'Sync All', AppLocale.zh: '同步全部'},
    'site_sync_success': {AppLocale.en: 'Site synced successfully', AppLocale.zh: '站点同步成功'},
    'site_sync_failed': {AppLocale.en: 'Sync failed', AppLocale.zh: '同步失败'},
    'site_syncing': {AppLocale.en: 'Syncing...', AppLocale.zh: '同步中...'},

    // Site Check-in
    'site_checkin': {AppLocale.en: 'Check-in', AppLocale.zh: '签到'},
    'site_checkin_all': {AppLocale.en: 'Check-in All', AppLocale.zh: '全部签到'},
    'site_checkin_success': {AppLocale.en: 'Check-in successful', AppLocale.zh: '签到成功'},
    'site_checkin_failed': {AppLocale.en: 'Check-in failed', AppLocale.zh: '签到失败'},
    'site_already_checked': {AppLocale.en: 'Already checked in', AppLocale.zh: '已签到'},
    'site_checkin_reward': {AppLocale.en: 'Reward', AppLocale.zh: '奖励'},
    'site_checkin_history': {AppLocale.en: 'Check-in History', AppLocale.zh: '签到记录'},
    'site_checkin_all_success': {
      AppLocale.en: 'All sites checked in',
      AppLocale.zh: '全部站点签到完成',
    },
    'site_checkin_all_failed': {
      AppLocale.en: 'Check-in all failed',
      AppLocale.zh: '批量签到失败',
    },

    // Site Redemption
    'site_redeem': {AppLocale.en: 'Redeem', AppLocale.zh: '兑换'},
    'site_redeem_code': {AppLocale.en: 'Redemption Code', AppLocale.zh: '兑换码'},
    'site_redeem_code_hint': {AppLocale.en: 'Enter redemption code', AppLocale.zh: '输入兑换码'},
    'site_redeem_success': {AppLocale.en: 'Redeemed successfully', AppLocale.zh: '兑换成功'},
    'site_redeem_failed': {AppLocale.en: 'Redemption failed', AppLocale.zh: '兑换失败'},
    'site_redeem_expired': {AppLocale.en: 'Code expired', AppLocale.zh: '兑换码已过期'},
    'site_redeem_value': {AppLocale.en: 'Value', AppLocale.zh: '面值'},
    'site_redemption_history': {
      AppLocale.en: 'Redemption History',
      AppLocale.zh: '兑换记录',
    },

    // Site Balance
    'site_balance': {AppLocale.en: 'Balance', AppLocale.zh: '余额'},
    'site_balance_history': {AppLocale.en: 'Balance History', AppLocale.zh: '余额历史'},
    'site_balance_prediction': {AppLocale.en: 'Balance Prediction', AppLocale.zh: '余额预测'},
    'site_days_remaining': {AppLocale.en: 'Days Remaining', AppLocale.zh: '剩余天数'},
    'site_daily_average': {AppLocale.en: 'Daily Average', AppLocale.zh: '日均消耗'},
    'site_weekly_average': {AppLocale.en: 'Weekly Average', AppLocale.zh: '周均消耗'},
    'site_recommendation': {AppLocale.en: 'Recommendation', AppLocale.zh: '建议'},

    // Site Channel Projection
    'site_channel': {AppLocale.en: 'Channel', AppLocale.zh: '渠道'},
    'site_channels': {AppLocale.en: 'Channels', AppLocale.zh: '渠道列表'},
    'site_channel_projection': {
      AppLocale.en: 'Channel Projection',
      AppLocale.zh: '渠道投影',
    },
    'site_channel_group': {AppLocale.en: 'Group', AppLocale.zh: '分组'},
    'site_channel_model': {AppLocale.en: 'Model', AppLocale.zh: '模型'},
    'site_channel_route': {AppLocale.en: 'Route', AppLocale.zh: '路由'},
    'site_channel_manual_model': {
      AppLocale.en: 'Manual Model',
      AppLocale.zh: '手动模型',
    },
    'site_channel_add_model': {
      AppLocale.en: 'Add Model',
      AppLocale.zh: '添加模型',
    },
    'site_channel_delete_model': {
      AppLocale.en: 'Delete Model',
      AppLocale.zh: '删除模型',
    },
    'site_channel_import': {AppLocale.en: 'Import', AppLocale.zh: '导入'},
    'site_channel_all_api_hub': {
      AppLocale.en: 'All API Hub',
      AppLocale.zh: '全部 API Hub',
    },
    'site_channel_met_api': {
      AppLocale.en: 'Met API',
      AppLocale.zh: '已满足 API',
    },
    'site_channel_no_channels': {
      AppLocale.en: 'No channels found',
      AppLocale.zh: '未找到渠道',
    },
    'site_channel_no_models': {
      AppLocale.en: 'No models configured',
      AppLocale.zh: '未配置模型',
    },
    'site_channel_model_name_hint': {
      AppLocale.en: 'Enter model name',
      AppLocale.zh: '输入模型名称',
    },
    'site_channel_delete_model_confirm': {
      AppLocale.en: 'Delete model "{name}"?',
      AppLocale.zh: '删除模型 "{name}"？',
    },
    'site_channel_route_type': {
      AppLocale.en: 'Route Type',
      AppLocale.zh: '路由类型',
    },
    'site_channel_account': {AppLocale.en: 'Account', AppLocale.zh: '账户'},
    'site_channel_import_placeholder': {
      AppLocale.en: 'Import functionality coming soon',
      AppLocale.zh: '导入功能即将推出',
    },

    // WebDAV Backup
    'webdav': {AppLocale.en: 'WebDAV Backup', AppLocale.zh: 'WebDAV 备份'},
    'webdav_base_url': {AppLocale.en: 'Base URL', AppLocale.zh: '服务器地址'},
    'webdav_username': {AppLocale.en: 'Username', AppLocale.zh: '用户名'},
    'webdav_password': {AppLocale.en: 'Password', AppLocale.zh: '密码'},
    'webdav_remote_path': {AppLocale.en: 'Remote Path', AppLocale.zh: '远程路径'},
    'webdav_auto_backup': {AppLocale.en: 'Auto Backup', AppLocale.zh: '自动备份'},
    'webdav_interval_disabled': {AppLocale.en: 'Disabled', AppLocale.zh: '禁用'},
    'webdav_interval_hourly': {AppLocale.en: 'Hourly', AppLocale.zh: '每小时'},
    'webdav_interval_daily': {AppLocale.en: 'Daily', AppLocale.zh: '每天'},
    'webdav_interval_weekly': {AppLocale.en: 'Weekly', AppLocale.zh: '每周'},
    'webdav_max_backups': {AppLocale.en: 'Max Backups', AppLocale.zh: '最大备份数'},
    'webdav_test': {AppLocale.en: 'Test', AppLocale.zh: '测试连接'},
    'webdav_backup_now': {AppLocale.en: 'Backup Now', AppLocale.zh: '立即备份'},
    'webdav_backups': {AppLocale.en: 'Remote Backups', AppLocale.zh: '远程备份列表'},
    'webdav_restore': {AppLocale.en: 'Restore', AppLocale.zh: '恢复'},
    'webdav_delete': {AppLocale.en: 'Delete', AppLocale.zh: '删除'},
    'webdav_test_success': {AppLocale.en: 'Connection successful', AppLocale.zh: '连接成功'},
    'webdav_test_failed': {AppLocale.en: 'Connection failed', AppLocale.zh: '连接失败'},
    'webdav_backup_success': {AppLocale.en: 'Backup completed', AppLocale.zh: '备份完成'},
    'webdav_backup_failed': {AppLocale.en: 'Backup failed', AppLocale.zh: '备份失败'},
    'webdav_no_backups': {AppLocale.en: 'No backups found', AppLocale.zh: '暂无备份'},
    'webdav_restore_confirm': {
      AppLocale.en: 'Restore backup "{name}"?',
      AppLocale.zh: '恢复备份 "{name}"？',
    },
    'webdav_delete_confirm': {
      AppLocale.en: 'Delete backup "{name}"?',
      AppLocale.zh: '删除备份 "{name}"？',
    },

    // WebAuthn / Passkey
    'webauthn': {AppLocale.en: 'WebAuthn', AppLocale.zh: 'WebAuthn'},
    'webauthn_rp_id': {AppLocale.en: 'RP ID', AppLocale.zh: 'RP ID'},
    'webauthn_rp_name': {AppLocale.en: 'RP Name', AppLocale.zh: 'RP 名称'},
    'webauthn_origins': {AppLocale.en: 'Allowed Origins', AppLocale.zh: '允许来源'},
    'webauthn_origins_hint': {
      AppLocale.en: 'Comma-separated URLs',
      AppLocale.zh: '逗号分隔的 URL',
    },
    'webauthn_credentials': {AppLocale.en: 'Credentials', AppLocale.zh: '凭证列表'},
    'webauthn_register': {AppLocale.en: 'Register', AppLocale.zh: '注册凭证'},
    'webauthn_delete': {AppLocale.en: 'Delete', AppLocale.zh: '删除'},
    'webauthn_delete_confirm': {
      AppLocale.en: 'Delete this credential?',
      AppLocale.zh: '删除此凭证？',
    },
    'webauthn_no_credentials': {AppLocale.en: 'No credentials', AppLocale.zh: '暂无凭证'},

    // Errors
    'error': {AppLocale.en: 'Error', AppLocale.zh: '错误'},
    'operation_failed': {
      AppLocale.en: 'Operation failed',
      AppLocale.zh: '操作失败',
    },
  };

  String t(String key, [Map<String, String>? args]) {
    var text = _strings[key]?[locale] ?? key;
    if (args != null) {
      args.forEach((k, v) {
        text = text.replaceAll('{$k}', v);
      });
    }
    return text;
  }

  static const localeMap = <AppLocale, Locale>{
    AppLocale.en: Locale('en'),
    AppLocale.zh: Locale('zh'),
  };

  static AppLocale fromLocale(Locale locale) {
    if (locale.languageCode.startsWith('zh')) return AppLocale.zh;
    return AppLocale.en;
  }
}
