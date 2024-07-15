BeginPackage["Notebook`Templates`", {
    "JerryI`Misc`Events`",
    "JerryI`Misc`Async`",
    "JerryI`Misc`Events`Promise`",
    "JerryI`Notebook`AppExtensions`",
    "JerryI`WLX`",
    "JerryI`WLX`Importer`",
    "JerryI`WLX`WebUI`",
    "Notebook`Editor`Snippets`"
}]


Begin["`Internal`"]

database = <||>;

$userLibraryPath = FileNameJoin[{Directory[], "UserTemplates"}];
$libraryPath = FileNameJoin[{$InputFileName // DirectoryName, "Library"}]

If[!FileExistsQ[ $userLibraryPath ], CreateDirectory[$userLibraryPath] ];

scan[filename_] := With[{name = FileBaseName[filename]},
    database[name] = filename
]

scan /@ Flatten[{FileNames["*.wln", $libraryPath, Infinity], FileNames["*.wln", $userLibraryPath, Infinity]}];

listener[OptionsPattern[] ] := 
With[{
    Controls = OptionValue["Controls"],
    Modals = OptionValue["Modals"],
    Path = If[DirectoryQ[#], #, DirectoryName[#] ] &@ OptionValue["Path"],
    Type = OptionValue["Type"]
},
    EventHandler[EventClone[Controls], {"new_from_template" -> Function[Null, 
        With[{
            promise = Promise[],
            cli = Global`$Client
        }, 
            EventFire[Modals, "Select", <|"Client"->cli, "Promise"->promise, "Title"->"Which template", "Options"->Keys[database]|>];
            Then[promise, Function[choise,

                With[{
                    p = Promise[]
                },
                    EventFire[Modals, "RequestPathToSave", <|
                        "Promise"->p,
                        "Title"->"Notebook & Template files",
                        "Ext"->"wln",
                        "Client"->cli
                    |>];

                    Then[p, Function[result, 
                        Module[{filename = result<>".wln"},
                            If[filename === ".wln", filename = name<>filename];
                            If[DirectoryName[filename] === "", filename = FileNameJoin[{Path, filename}] ];

                            With[{name = filename, template = Values[database][[choise["Result"] ]]},
                                CopyFile[template,  name];

                                With[{dir = FileNameJoin[{template // DirectoryName, "attachments"}], targetDir =  FileNameJoin[{name // DirectoryName, "attachments"}]},
                                    If[FileExistsQ[dir],
                                        If[!FileExistsQ[targetDir ], CreateDirectory[ targetDir ] ] ;
                                        Map[Function[n, CopyFile[n, FileNameJoin[{targetDir, FileNameTake[n] }] ] ],  
                                            FileNames["*.*", dir ]
                                        ];
                                    ]
                                ];

                                If[Type === "ExtendedApp", 
                                    WebUILocation[StringJoin["/folder/", URLEncode[name] ], cli, "Target"->_];
                                ,
                                    WebUILocation[StringJoin["/", URLEncode[name] ], cli, "Target"->_];
                                ];
                            ]
                        ];
                    ], Function[result, Echo["!!!R!!"]; Echo[result] ] ];

                ]

            ] ];
        ]        
    ]}];
    ""
]

Options[listener] = {"Path"->"", "Parameters"->"", "Modals"->"", "AppEvent"->"", "Controls"->"", "Messanger"->""}


AppExtensions`TemplateInjection["AppTopBar"] = listener;


SnippetsCreateItem[
    "newFileFromTemplate", 

    "Template"->ImportComponent["Ico.wlx"] , 
    "Title"->"New notebook from template"
];

(* just fwd *)
EventHandler[SnippetsEvents, {
    "newFileFromTemplate" -> Function[assoc, EventFire[assoc["Controls"], "new_from_template", True] ]
}];

End[]
EndPackage[]