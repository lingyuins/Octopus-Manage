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
    'select_channel': {AppLocale.en: 'Select Channel', AppLocale.zh: '选择渠道'},
    'load_channels_failed': {
      AppLocale.en: 'Failed to load channels',
      AppLocale.zh: '加载渠道失败',
    },
    'collapse_text': {AppLocale.en: 'Collapse', AppLocale.zh: '收起'},

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
