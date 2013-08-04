USING: tools.deploy.config ;
H{
    { deploy-c-types? f }
    { deploy-help? f }
    { deploy-name "minesweeper_gui" }
    { "stop-after-last-window?" t }
    { deploy-unicode? f }
    { deploy-console? t }
    { deploy-io 3 }
    { deploy-reflection 1 }
    { deploy-ui? t }
    { deploy-word-defs? f }
    { deploy-threads? t }
    { deploy-math? t }
    { deploy-word-props? f }
}
