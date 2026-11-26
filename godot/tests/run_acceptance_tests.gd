extends SceneTree

## Headless CLI runner for the ZenoFit v1.0 Acceptance Test Suite.
## Run with:
##   godot --headless --xr-mode off --path godot -s res://tests/run_acceptance_tests.gd

func _initialize() -> void:
	var suite := ZenoAcceptanceSuite.new()
	var summary := suite.run_all(get_root())
	print("==================================================================")
	print("ZENOFIT (GODOT 4.7) v1.0 ACCEPTANCE TEST SUITE")
	print("==================================================================")
	for line in summary["log"]:
		print(line)
	print("------------------------------------------------------------------")
	print("TOTAL PASSED: %d | TOTAL FAILED: %d" % [int(summary["passed"]), int(summary["failed"])])
	print("==================================================================")
	await process_frame
	quit(0 if int(summary["failed"]) == 0 else 1)
