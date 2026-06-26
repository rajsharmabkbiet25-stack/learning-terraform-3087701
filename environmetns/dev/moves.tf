moved {
    from = module.blog_vpc
    to = module.dev.module.blog_vpc
}

moved {
    from = module.blog_sg
    to = module.dev.module.blog_sg
}

moved {
    from = module.web_alb
    to = module.dev.module.web_alb
}

moved {
    from = module.blog_asg
    to = module.dev.module.blog_asg
}

moved {
    from = aws_lb_target_group.blog
    to = module.dev.aws_lb_target_group.blog
}

  