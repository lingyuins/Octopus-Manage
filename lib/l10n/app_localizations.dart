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
    'api_keys': {AppLocale.en: 'API Keys', AppLocale.zh: 'API Key'},
    'logs': {AppLocale.en: 'Logs', AppLocale.zh: '日志'},
    'settings': {AppLocale.en: 'Settings', AppLocale.zh: '设置'},

    // Dashboard
    'dashboard': {AppLocale.en: 'Dashboard', AppLocale.zh: '仪表盘'},
    'today': {AppLocale.en: 'Today', AppLocale.zh: '今日'},
    'total': {AppLocale.en: 'Total', AppLocale.zh: '总计'},
    'requests': {AppLocale.en: 'Requests', AppLocale.zh: '请求数'},
    'failed': {AppLocale.en: 'Failed', AppLocale.zh: '失败'},
    'cost': {AppLocale.en: 'Cost', AppLocale.zh: '费用'},
    'tokens': {AppLocale.en: 'Tokens', AppLocale.zh: 'Token数'},
    'success_rate': {AppLocale.en: 'Success Rate', AppLocale.zh: '成功率'},
    'avg_wait': {AppLocale.en: 'Avg Wait', AppLocale.zh: '平均等待'},
    'daily_requests': {AppLocale.en: 'Daily Requests', AppLocale.zh: '每日请求'},
    'daily_cost': {AppLocale.en: 'Daily Cost', AppLocale.zh: '每日费用'},
    'daily_chart': {AppLocale.en: 'Daily Trend', AppLocale.zh: '每日趋势'},

    // Ranking
    'ranking': {AppLocale.en: 'Ranking', AppLocale.zh: '排行榜'},
    'sort_by_cost': {AppLocale.en: 'Cost', AppLocale.zh: '费用'},
    'sort_by_count': {AppLocale.en: 'Count', AppLocale.zh: '请求数'},
    'sort_by_tokens': {AppLocale.en: 'Tokens', AppLocale.zh: 'Token数'},
    'sort_by_key_usage': {AppLocale.en: 'Key Usage', AppLocale.zh: 'Key 用量'},
    'api_key_leaderboard': {AppLocale.en: 'API Key Leaderboard', AppLocale.zh: 'API Key 排行'},
    'no_data': {AppLocale.en: 'No data', AppLocale.zh: '暂无数据'},
    'success_rate_label': {AppLocale.en: 'Success Rate', AppLocale.zh: '成功率'},
    'channel_leaderboard': {AppLocale.en: 'Channel Leaderboard', AppLocale.zh: '渠道排行'},

    // Channel
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
    'no_groups': {AppLocale.en: 'No groups', AppLocale.zh: '暂无分组'},
    'no_api_keys': {AppLocale.en: 'No API keys', AppLocale.zh: '暂无 API Key'},
    'no_logs': {AppLocale.en: 'No logs', AppLocale.zh: '暂无日志'},
    'create_channel': {AppLocale.en: 'Create Channel', AppLocale.zh: '创建渠道'},
    'edit_channel': {AppLocale.en: 'Edit Channel', AppLocale.zh: '编辑渠道'},
    'channel_name': {AppLocale.en: 'Channel Name', AppLocale.zh: '渠道名称'},
    'channel_type': {AppLocale.en: 'Channel Type', AppLocale.zh: '渠道类型'},
    'base_url': {AppLocale.en: 'Base URL', AppLocale.zh: '基础URL'},
    'model': {AppLocale.en: 'Model', AppLocale.zh: '模型'},
    'custom_model': {AppLocale.en: 'Custom Model', AppLocale.zh: '自定义模型'},
    'enabled': {AppLocale.en: 'Enabled', AppLocale.zh: '启用'},
    'proxy': {AppLocale.en: 'Proxy', AppLocale.zh: '代理'},
    'auto_sync': {AppLocale.en: 'Auto Sync', AppLocale.zh: '自动同步'},

    // Group
    'first_token_timeout': {
      AppLocale.en: 'First Token Timeout',
      AppLocale.zh: '首Token超时',
    },
    'session_keep': {AppLocale.en: 'Session Keep', AppLocale.zh: '会话保持'},
    'delete_group': {AppLocale.en: 'Delete Group', AppLocale.zh: '删除分组'},
    'create_group': {AppLocale.en: 'Create Group', AppLocale.zh: '创建分组'},
    'edit_group': {AppLocale.en: 'Edit Group', AppLocale.zh: '编辑分组'},
    'group_name': {AppLocale.en: 'Group Name', AppLocale.zh: '分组名称'},
    'mode': {AppLocale.en: 'Mode', AppLocale.zh: '模式'},
    'match_regex': {AppLocale.en: 'Match Regex', AppLocale.zh: '匹配正则'},
    'group_items': {AppLocale.en: 'Group Items', AppLocale.zh: '分组项'},
    'channel_id': {AppLocale.en: 'Channel ID', AppLocale.zh: '渠道ID'},
    'model_name': {AppLocale.en: 'Model Name', AppLocale.zh: '模型名称'},
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
    'remember_me': {AppLocale.en: 'Remember me', AppLocale.zh: '记住我'},

    // Misc
    'second': {AppLocale.en: 's', AppLocale.zh: '秒'},
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
