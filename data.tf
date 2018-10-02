data "null_data_source" "squid_tags" {
  inputs = {
    "Environment" = "${var.environment}"
    "Name"        = "squid-s3-proxy-${var.environment}"
  }
}

data "null_data_source" "squid_merged_tags" {
  inputs = "${merge(var.extra_tags, data.null_data_source.squid_tags.outputs)}"
}

data "null_data_source" "squid_tag_list" {
  count = "${length(keys(data.null_data_source.squid_merged_tags.outputs))}"

  inputs = {
    key                 = "${element(keys(data.null_data_source.squid_merged_tags.outputs), count.index)}"
    value               = "${element(values(data.null_data_source.squid_merged_tags.outputs), count.index)}"
    propagate_at_launch = true
  }
}
