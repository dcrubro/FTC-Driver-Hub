//
//  CommandConstants.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

enum CommandName {
    static let restartRobot               = "CMD_RESTART_ROBOT"
    static let setMatchNumber             = "CMD_SET_MATCH_NUMBER"
    static let notifyOpModeState          = "CMD_NOTIFY_ROBOT_STATE"
    static let requestOpModes             = "CMD_REQUEST_OP_MODE_LIST"
    static let notifyOpModes              = "CMD_NOTIFY_OP_MODE_LIST"
    static let activateConfiguration      = "CMD_ACTIVATE_CONFIGURATION"
    static let saveConfiguration          = "CMD_SAVE_CONFIGURATION"
    static let deleteConfiguration        = "CMD_DELETE_CONFIGURATION"
    static let requestActiveConfiguration = "CMD_REQUEST_ACTIVE_CONFIG"
    static let notifyActiveConfiguration  = "CMD_NOTIFY_ACTIVE_CONFIGURATION"
    static let requestConfigurations      = "CMD_REQUEST_CONFIGURATIONS"
    static let requestConfigurationsResp  = "CMD_REQUEST_CONFIGURATIONS_RESP"
    static let requestConfiguration       = "CMD_REQUEST_PARTICULAR_CONFIGURATION"
    static let requestConfigurationResp   = "CMD_REQUEST_PARTICULAR_CONFIGURATION_RESP"
    static let initOpMode                 = "CMD_INIT_OP_MODE"
    static let runOpMode                  = "CMD_RUN_OP_MODE"
    static let notifyInitOpMode           = "CMD_NOTIFY_INIT_OP_MODE"
    static let notifyRunOpMode            = "CMD_NOTIFY_RUN_OP_MODE"
    static let showStacktrace             = "CMD_SHOW_STACKTRACE"
}
