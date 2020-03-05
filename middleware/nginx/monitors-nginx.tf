resource "signalfx_detector" "nginx_heartbeat" {
	name = "${upper(join("", formatlist("[%s]", var.prefixes_slug)))}[${upper(var.environment)}] System Heartbeat Check"

	program_text = <<-EOF
		from signalfx.detectors.not_reporting import not_reporting
		signal = data('nginx_requests', filter=(not filter('aws_state', '*terminated}', '*stopped}')) and (not filter('gcp_status', '*TERMINATED}', '*STOPPING}')) and (not filter('azure_power_state', 'stop*', 'deallocat*')) and ${module.filter-tags.filter_custom})
		not_reporting.detector(stream=signal, resource_identifier=['host'], duration='${var.nginx_heartbeat_timeframe}').publish('CRIT')
	EOF

	rule {
		description = "System has not reported in ${var.nginx_heartbeat_timeframe}"
		severity = "Critical"
		detect_label = "CRIT"
		disabled = coalesce(var.nginx_heartbeat_disabled_flag,var.disable_detectors)
                notifications = coalesce(split(";",var.nginx_heartbeat_notifications),split(";",var.notifications))
	}
}

resource "signalfx_detector" "nginx_dropped_connections" {
	name = "${upper(join("", formatlist("[%s]", var.prefixes_slug)))}[${upper(var.environment)}] Nginx dropped connections"

	program_text = <<-EOF
		signal = data('connections.failed', filter=${module.filter-tags.filter_custom})${var.nginx_aggregation_function}.${var.nginx_transformation_function}(over='${var.nginx_transformation_window}')
		detect(when(signal > ${var.nginx_threshold_critical})).publish('CRIT')
		detect(when(signal > ${var.nginx_threshold_warning})).publish('WARN')
	EOF

	rule {
		description = "${var.nginx_transformation_function} nginx dropped connections over ${var.nginx_transformation_window} > ${var.nginx_threshold_critical}"
		severity = "Critical"
		detect_label = "CRIT"
		disabled = coalesce(var.nginx_critical_disabled_flag,var.disable_nginx_detector,var.disable_detectors)
		notifications = coalesce(split(";",var.nginx_critical_notifications),split(";",var.nginx_notifications),split(";",var.notifications))
	}
        
		rule {
		description = "${var.nginx_transformation_function} nginx dropped connections over ${var.nginx_transformation_window} > ${var.nginx_threshold_warning}"
		severity = "Warning"
		detect_label = "WARN"
		disabled = coalesce(var.nginx_warning_disabled_flag,var.disable_nginx_detector,var.disable_detectors)
		notifications = coalesce(split(";",var.nginx_warning_notifications),split(";",var.nginx_notifications),split(";",var.notifications))
	}
}
