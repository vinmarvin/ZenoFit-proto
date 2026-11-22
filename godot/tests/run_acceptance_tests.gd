extends SceneTree

## Headless CLI runner for the ZenoFit Acceptance Test Suite (AT-01..AT-35 + v0.4 Dojo Flow).
## Run with:
##   godot --headless --xr-mode off --path godot -s res://tests/run_acceptance_tests.gd

func _init() -> void:
	var suite := ZenoAcceptanceSuite.new()
	var summary := suite.run_all()
	print("==================================================================")
	print("ZENOFIT (GODOT 4.7) ACCEPTANCE TEST SUITE (AT-01 .. AT-35 + v0.4)")
	print("==================================================================")
	for line in summary["log"]:
		print(line)
	print("------------------------------------------------------------------")
	print("TOTAL PASSED: %d | TOTAL FAILED: %d" % [int(summary["passed"]), int(summary["failed"])])
	print("==================================================================")
	quit(0 if int(summary["failed"]) == 0 else 1)
